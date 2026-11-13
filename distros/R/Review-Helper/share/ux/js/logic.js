// Pure functions used by the page. No DOM access, so node tests can load them.

export function escapeHtml(s) {
    return String(s).replace(/[&<>"']/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' })[c]);
}

// The highlight.js language for each file kind (standards/FORMAT.md, "File
// kind"); kinds not here (text, and any the page does not know) are plain.
const LANG = {
    perl: 'perl', javascript: 'javascript', typescript: 'typescript', css: 'css', html: 'xml', xml: 'xml', markdown: 'markdown',
    shell: 'bash', sql: 'sql', json: 'json', yaml: 'yaml', ini: 'ini', toml: 'ini', python: 'python', ruby: 'ruby', go: 'go',
    rust: 'rust', c: 'c', cpp: 'cpp', java: 'java', makefile: 'makefile', dockerfile: 'dockerfile', diff: 'diff',
};

export function langForKind(kind) {
    return Object.hasOwn(LANG, kind) ? LANG[kind] : null;
}

// Split highlighter output into one HTML string per source line. A span that
// crosses a newline is closed at the end of the line and reopened on the next,
// so every line is balanced on its own.
export function splitHighlighted(html) {
    const lines = [];
    const open = [];
    let cur = '';
    const re = /(<span[^>]*>)|(<\/span>)|([^<]+)/g;
    let m;
    while ((m = re.exec(html))) {
        if (m[1]) {
            open.push(m[1]);
            cur += m[1];
        }
        else if (m[2]) {
            open.pop();
            cur += m[2];
        }
        else {
            const parts = m[3].split('\n');
            cur += parts[0];
            for (let i = 1; i < parts.length; i++) {
                lines.push(cur + '</span>'.repeat(open.length));
                cur = open.join('') + parts[i];
            }
        }
    }
    lines.push(cur + '</span>'.repeat(open.length));
    return lines;
}

// Highlight a whole file once and return its lines as HTML; lines[0] is line 1.
export function highlightLines(hljs, text, kind) {
    if (text.endsWith('\n')) text = text.slice(0, -1);
    const lang = langForKind(kind);
    if (!lang || !hljs) return text.split('\n').map(escapeHtml);
    return splitHighlighted(hljs.highlight(text, { language: lang, ignoreIllegals: true }).value);
}

// Tree and page color for a file: added, deleted, changed (an existing file
// whose content changed, whatever its size did), or '' (a rename alone).
export function sizeClass(file) {
    if (file.status === 'A') return 'added';
    if (file.status === 'D') return 'deleted';
    return file.status === 'R' && sameContent(file) ? '' : 'changed';
}

// Whether a file change left the content as it was: a rename or mode change
// alone.
export function sameContent(file) {
    return !file.added && !file.removed && !file.changed && file.size_before === file.size_after;
}

// Whether the agent splits a file into sections: a text file its commit
// adds, or changes a line of without deleting it (the split item of
// standards/FORMAT.md, "The fill sheet").
export function needsSplit(file) {
    return file.size_unit === 'lines' && file.status !== 'D' && (file.status === 'A' || !!(file.added || file.removed || file.changed));
}

// What a request on an item may ask for: a split only of a file the agent
// splits (the server refuses the others: standards/API.md, "POST
// /api/request").
export function requestKinds(item) {
    return item.type === 'file' && needsSplit(item.file) ? ['debate', 'split'] : ['debate'];
}

// A file's path as the page shows it: a renamed file's old path, an arrow
// and its new path.
export function fileLabel(file) {
    return file.old_path && file.old_path !== file.path ? `${file.old_path} → ${file.path}` : file.path;
}

// A renamed file's badge: 'renamed' when its content is the same, else
// 'renamed + changed'; null for a file that was not renamed.
export function renameBadge(file) {
    if (!file.old_path || file.old_path === file.path) return null;
    return sameContent(file) ? 'renamed' : 'renamed + changed';
}

// A commit's renames as its facts give them, e.g. '3 files (2 changed)';
// null when it renamed nothing.
export function renameFact(files) {
    const renamed = files.filter(f => renameBadge(f));
    if (!renamed.length) return null;
    const changed = renamed.filter(f => !sameContent(f)).length;
    return `${renamed.length} file${renamed.length === 1 ? '' : 's'} (${changed} changed)`;
}

// Order a commit's files. Reading order falls back to A-Z until the agent has
// set it for the commit; `pending` reports that fallback.
export function orderFiles(files, mode, orderSet) {
    const az = (a, b) => (a.path < b.path ? -1 : a.path > b.path ? 1 : 0);
    const list = [...files];
    if (mode === 'reading' && orderSet) {
        list.sort((a, b) => (a.read_position ?? Infinity) - (b.read_position ?? Infinity) || az(a, b));
        return { files: list, pending: false };
    }
    list.sort(az);
    return { files: list, pending: mode === 'reading' };
}

// The commit tree: mainline entries (no merge_id), and for each merge the
// commits it brought in, all in position order. An entry whose merge is
// missing from the list counts as mainline.
export function commitTree(commits) {
    const byId = new Map(commits.map(c => [c.id, c]));
    const mainline = [];
    const kids = new Map();
    for (const c of [...commits].sort((a, b) => a.position - b.position)) {
        if (c.merge_id == null || !byId.has(c.merge_id)) mainline.push(c);
        else if (kids.has(c.merge_id)) kids.get(c.merge_id).push(c);
        else kids.set(c.merge_id, [c]);
    }
    return { mainline, kids, byId };
}

// A commit and every commit nested under it.
export function subtree(tree, c) {
    return [c, ...(tree.kids.get(c.id) || []).flatMap(k => subtree(tree, k))];
}

// The merges a commit sits in, outermost (mainline) first.
export function mergePath(tree, c) {
    const path = [];
    for (let m = tree.byId.get(c.merge_id); m; m = tree.byId.get(m.merge_id)) path.unshift(m);
    return path;
}

// The first paragraph or bullet of agent text, for one-line listings.
export function firstLine(text) {
    const b = textBlocks(text)[0];
    return b ? (b.type === 'p' ? b.text : b.items[0]) : null;
}

// SVG is text (diffed, takes line feedback), but its file tab also shows it
// as a picture.
export function isSvg(path) {
    return /\.svg$/i.test(String(path ?? ''));
}

// The header's "user@host · repo" from /api/review's identity, or null.
export function identityLine(identity) {
    if (!identity) return null;
    const who = [identity.user, identity.host].filter(Boolean).join('@');
    const line = [who, identity.repo].filter(Boolean).join(' · ');
    return line || null;
}

// When the review a tab showed before ({ id, title }, as stored) is not the
// one now loaded: { was, now, text }, text being the warning. Else null; a
// tab that stored nothing, or something unreadable, has nothing to compare.
export function staleReview(stored, review) {
    let was;
    try { was = JSON.parse(stored) }
    catch { return null }
    if (!was?.id || was.id === review.id) return null;
    const name = r => (r.title ? `"${r.title}" (${r.id})` : r.id);
    const now = { id: review.id, title: review.title };
    return { was, now, text: `This tab was showing review ${name(was)}; this server is now serving review ${name(now)}.` };
}

// The URL if it is an http(s) one, else null: a link to anything else could
// run script on this page.
export function webUrl(url) {
    try { return ['http:', 'https:'].includes(new URL(url).protocol) ? url : null }
    catch { return null }
}

export function inRanges(line, ranges) {
    return ranges.some(([s, e]) => line >= s && line <= e);
}

// View state <-> URL fragment.
//
// State: { it: number|null, at: string|null, g: number|null, w: 'f'|'a'|null, u: [[slot, value]], commits: { <commit id>:
//   { panel, commits: { <commit id>: true }, view: path|undefined,
//     files: { <file id>: { panel, sections: { <section id>: panel } } } } } }
// panel is '' (summary only), 'd' (diff), 'v' (view file) or, for a merge,
// 'r' (its conflict resolution). A file's
// sections are the ones expanded in place. A merge's commits are the ones it
// brought in that are open; each keeps its own entry.
// view is a file shown whole as it is at the commit, which need not have
// changed it. g is the guide step shown, null outside guide mode. w says the
// guide bar walks the flags instead of the guide: 'f' (walk new) those the
// reviewer has not seen, 'a' (walk all) seen ones too, either followed by
// 'r' or 'y' to walk the red or yellow flags only. u is what the guide step
// shown changed, to undo when leaving it (see stepChanges).
//
// Fragment: i=<iteration>&at=<element id>&g=<step>&w=<walk>&u=<changes>&c<commit id>=<tokens>, where tokens
// are comma separated: an optional bare panel for the commit, then
// c<commit id> for each open commit, p<encoded path> for the view, then
// f<file id>[~panel] each followed by its s<section id>[~panel]. Changes
// are comma separated slot[~encoded value], a slot with no value absent.
export function emptyState() {
    return { it: null, at: null, g: null, w: null, u: [], commits: {} };
}

const byNum = (a, b) => a - b;

export function encodeCommit(cs) {
    if (!cs) return '';
    const tok = [];
    // Only the panels the fragment can carry: anything else would end up
    // in the URL as tokens or parameters of its own.
    if (/^[dvr]$/.test(cs.panel)) tok.push(cs.panel);
    for (const cid of Object.keys(cs.commits || {}).map(Number).sort(byNum)) tok.push('c' + cid);
    if (cs.view) tok.push('p' + encodeURIComponent(cs.view));
    for (const fid of Object.keys(cs.files || {}).map(Number).sort(byNum)) {
        const fs = cs.files[fid];
        tok.push('f' + fid + (/^[dv]$/.test(fs.panel) ? '~' + fs.panel : ''));
        for (const sid of Object.keys(fs.sections || {}).map(Number).sort(byNum)) {
            const p = fs.sections[sid];
            tok.push('s' + sid + (/^[dv]$/.test(p) ? '~' + p : ''));
        }
    }
    return tok.join(',');
}

export function encodeState(state) {
    const parts = [];
    if (state.it != null) parts.push('i=' + state.it);
    if (state.at) parts.push('at=' + encodeURIComponent(state.at));
    if (state.g != null) parts.push('g=' + state.g);
    if (state.w) parts.push('w=' + state.w);
    if (state.u?.length) parts.push('u=' + state.u.map(([k, v]) => (v == null ? k : k + '~' + encodeURIComponent(v))).join(','));
    for (const cid of Object.keys(state.commits).map(Number).sort(byNum)) {
        const spec = encodeCommit(state.commits[cid]);
        if (spec) parts.push('c' + cid + '=' + spec);
    }
    return parts.join('&');
}

export function decodeState(hash) {
    const state = emptyState();
    for (const part of (hash || '').replace(/^#/, '').split('&')) {
        const eq = part.indexOf('=');
        if (eq < 0) continue;
        const key = part.slice(0, eq);
        const val = part.slice(eq + 1);
        if (key === 'i' && /^\d+$/.test(val)) state.it = Number(val);
        else if (key === 'at') {
            try { state.at = decodeURIComponent(val) || null }
            catch { /* malformed; dropped */ }
        }
        else if (key === 'g' && /^[1-9]\d*$/.test(val)) state.g = Number(val);
        else if (key === 'w' && /^[fa][ry]?$/.test(val)) state.w = val;
        else if (key === 'u') state.u = decodeChanges(val);
        else if (/^c\d+$/.test(key)) {
            const cs = { panel: '', commits: {}, files: {} };
            let file = null;
            for (const tok of val.split(',')) {
                if (/^[dvr]$/.test(tok)) {
                    cs.panel = tok;
                    continue;
                }
                if (tok[0] === 'p') {
                    try { cs.view = decodeURIComponent(tok.slice(1)) || undefined }
                    catch { /* malformed; dropped */ }
                    continue;
                }
                const m = /^([cfs])(\d+)(?:~([dv]))?$/.exec(tok);
                if (!m) continue;
                if (m[1] === 'c') cs.commits[m[2]] = true;
                else if (m[1] === 'f') file = cs.files[m[2]] = { panel: m[3] || '', sections: {} };
                else if (file) file.sections[m[2]] = m[3] || '';
            }
            if (encodeCommit(cs)) state.commits[key.slice(1)] = cs;
        }
    }
    return state;
}

function decodeChanges(val) {
    const changes = [];
    for (const tok of val.split(',')) {
        const i = tok.indexOf('~');
        const slot = i < 0 ? tok : tok.slice(0, i);
        if (!SLOT.test(slot)) continue;
        let v = null;
        try { v = i < 0 ? null : decodeURIComponent(tok.slice(i + 1)) }
        catch { continue }
        if (fitsSlot(slot, v)) changes.push([slot, v]);
    }
    return changes;
}

// Whether a value is one the slot can hold (see slots): a view's path, an
// open commit's '', a file's or section's panel, a commit's panel.
function fitsSlot(slot, v) {
    if (v == null) return true;
    const [, , view, kid, fid] = SLOT.exec(slot);
    if (view) return v !== '';
    if (kid) return v === '';
    return (fid ? /^[dv]?$/ : /^[dvr]?$/).test(v);
}

// A view state's slots: c<cid> a commit's panel, c<cid>p its view,
// c<cid>c<kid> a commit it has open, c<cid>f<fid> an expanded file's panel,
// c<cid>f<fid>s<sid> an expanded section's panel.
const SLOT = /^c(\d+)(?:(p)|c(\d+)|f(\d+)(?:s(\d+))?)?$/;

function slots(s) {
    const m = new Map();
    for (const [cid, cs] of Object.entries(s.commits)) {
        const c = 'c' + cid;
        if (cs.panel) m.set(c, cs.panel);
        if (cs.view != null) m.set(c + 'p', cs.view);
        for (const k of Object.keys(cs.commits || {})) m.set(`${c}c${k}`, '');
        for (const [fid, fs] of Object.entries(cs.files || {})) {
            m.set(`${c}f${fid}`, fs.panel);
            for (const [sid, p] of Object.entries(fs.sections || {})) m.set(`${c}f${fid}s${sid}`, p);
        }
    }
    return m;
}

// What a guide step changed from view state before to after: [slot, value
// before] pairs, a value null when the slot was absent (a commit's panel
// closed, a file or section collapsed).
export function stepChanges(before, after) {
    const [a, b] = [slots(before), slots(after)];
    const changes = [];
    for (const k of new Set([...a.keys(), ...b.keys()])) {
        if ((a.get(k) ?? null) !== (b.get(k) ?? null)) changes.push([k, a.get(k) ?? null]);
    }
    return changes.sort(([x], [y]) => (x < y ? -1 : x > y ? 1 : 0));
}

// Put back in view state s what stepChanges recorded, leaving everything
// else as it is. tree (commitTree) tells a commit a merge brought in:
// nothing is put back under one no merge has open now (the reader closed
// it), as a commit hidden under its merge must carry no state; what the step
// added is still taken away, and closing one drops everything under it, as
// a click does. A merge's open commits go back first, an outer merge's
// before an inner one's, then files, then sections, so what is put back is
// there for what follows.
export function undoChanges(s, changes, tree = null) {
    const commit = cid => tree?.byId.get(Number(cid));
    const isOpen = cid => !tree?.byId.has(commit(cid)?.merge_id) || Object.values(s.commits).some(cs => cs.commits?.[cid]);
    const cidOf = ([k]) => SLOT.exec(k)?.[1];
    const shown = x => cidOf(x) && (x[1] == null || isOpen(cidOf(x)));
    const drop = cid => {
        for (const c of commit(cid) ? subtree(tree, commit(cid)) : [{ id: cid }]) delete s.commits[c.id];
    };
    const kind = ([k]) => (/^c\d+c\d+$/.test(k) ? 0 : /s\d+$/.test(k) ? 2 : 1);
    let left = changes.filter(x => kind(x) === 0);
    for (let n = -1; left.length !== n;) {
        n = left.length;
        const next = [];
        for (const x of left) {
            if (shown(x)) undoSlot(s, x, drop);
            else next.push(x);
        }
        left = next;
    }
    for (const x of [1, 2].flatMap(n => changes.filter(y => kind(y) === n))) if (shown(x)) undoSlot(s, x, drop);
}

// Put one slot back; drop(cid) removes a commit closed and all under it.
function undoSlot(s, [slot, val], drop) {
    const [, cid, view, kid, fid, sid] = SLOT.exec(slot);
    const cs = (s.commits[cid] ??= { panel: '', commits: {}, files: {} });
    if (view) {
        if (val == null) delete cs.view;
        else cs.view = val;
    }
    else if (kid) {
        if (val != null) cs.commits[kid] = true;
        else if (cs.commits[kid]) {
            delete cs.commits[kid];
            drop(kid);
        }
    }
    else if (sid) {
        const fs = cs.files[fid];
        if (fs && val == null) delete fs.sections[sid];
        else if (fs) fs.sections[sid] = val;
    }
    else if (fid) {
        if (val == null) delete cs.files[fid];
        else (cs.files[fid] ??= { panel: '', sections: {} }).panel = val;
    }
    else cs.panel = val ?? '';
}

// Diff rows. Hunk lines are { type: ' '|'-'|'+', text, old, new }.
function hunkHeader(h) {
    return `@@ -${h.old_start},${h.old_count} +${h.new_start},${h.new_count} @@`;
}

// A named unit's diff comes in parts, its code and its documentation, with
// nothing from between them. A row names each part that follows another, and
// the documentation even when it comes first.
function partRow(hunks, i) {
    const part = hunks[i].part;
    if (!part || part === (i ? hunks[i - 1].part : 'code')) return [];
    let j = i;
    while (hunks[j + 1]?.part === part) j++;
    const [a, b] = [hunks[i].new_start, hunks[j].new_start + hunks[j].new_count - 1];
    const label = (part === 'docs' ? 'documentation' : part) + (a === b ? ` — line ${a}` : ` — lines ${a}–${b}`);
    return [{ kind: 'part', label }];
}

export function unifiedRows(hunks) {
    const rows = [];
    for (const [i, h] of hunks.entries()) {
        rows.push(...partRow(hunks, i), { kind: 'hunk', header: hunkHeader(h) });
        for (const l of h.lines) rows.push({ kind: 'line', type: l.type, old: l.old ?? null, new: l.new ?? null, text: l.text });
    }
    return rows;
}

// Side by side: context lines fill both sides; a run of removals followed by
// a run of additions is paired row by row, the longer run against blanks.
export function splitRows(hunks) {
    const rows = [];
    for (const [n, h] of hunks.entries()) {
        rows.push(...partRow(hunks, n), { kind: 'hunk', header: hunkHeader(h) });
        const lines = h.lines;
        let i = 0;
        while (i < lines.length) {
            const l = lines[i];
            if (l.type === ' ') {
                rows.push({
                    kind: 'pair',
                    left:  { type: ' ', line: l.old, text: l.text },
                    right: { type: ' ', line: l.new, text: l.text },
                });
                i++;
                continue;
            }
            const del = [];
            const add = [];
            while (i < lines.length && lines[i].type === '-') del.push(lines[i++]);
            while (i < lines.length && lines[i].type === '+') add.push(lines[i++]);
            for (let k = 0; k < Math.max(del.length, add.length); k++) {
                const d = del[k];
                const a = add[k];
                rows.push({
                    kind: 'pair',
                    left:  d ? { type: '-', line: d.old, text: d.text } : null,
                    right: a ? { type: '+', line: a.new, text: a.text } : null,
                });
            }
        }
    }
    return rows;
}

// Agent text: blank-line separated paragraphs; lines starting "- " or "* "
// form bullet lists. Returns [{ type: 'p', text } | { type: 'ul', items }].
export function textBlocks(text) {
    const blocks = [];
    for (const chunk of String(text ?? '').split(/\n\s*\n/)) {
        let para = [];
        let list = null;
        const flush = () => {
            if (para.length) blocks.push({ type: 'p', text: para.join(' ') });
            para = [];
        };
        for (const raw of chunk.split('\n')) {
            const line = raw.trim();
            if (!line) continue;
            const m = /^[-*]\s+(.*)$/.exec(line);
            if (m) {
                flush();
                if (!list) blocks.push(list = { type: 'ul', items: [] });
                list.items.push(m[1]);
            }
            else if (list && /^\s/.test(raw)) list.items[list.items.length - 1] += ' ' + line;
            else {
                list = null;
                para.push(line);
            }
        }
        flush();
    }
    return blocks;
}

// Split inline text on backticks: [{ code: bool, text }].
export function inlineCode(text) {
    return String(text).split('`').map((t, i) => ({ code: i % 2 === 1, text: t })).filter(p => p.text !== '');
}

// ---- flags, feedback and requests ----

export function rangesOverlap(s, e, ranges) {
    return ranges.some(([a, b]) => s <= b && e >= a);
}

// Flags anchor to after-commit lines, except in a deleted file, which has
// only before-commit lines.
export function flagSide(file) {
    return file.status === 'D' ? 'old' : 'new';
}

// The entry a revision names. Every topic of a squashed iteration split into
// topics is an entry with the head's revision: the topic picks one, else the one
// holding the path, else the first. Null when none matches.
export function entryFor(commits, revision, path, topic) {
    const found = commits.filter(c => c.revision === revision);
    if (topic != null) return found.find(c => c.topic === topic) ?? null;
    if (found.length < 2) return found[0] ?? null;
    return (path != null && found.find(c => c.files.some(f => f.path === path))) || found[0];
}

// The entry a flag is on: the one it names, or else by its revision and path.
export function flagEntry(flag, commits) {
    return flag.entry != null ? commits.find(c => c.id === flag.entry) ?? null : entryFor(commits, flag.commit, flag.path);
}

// Flags of a tree node: a commit (no file), a file, or a section of it.
export function flagsOf(flags, commit, file, section) {
    return flags.filter(fl => {
        if (fl.entry != null ? fl.entry !== commit.id : fl.commit !== commit.revision) return false;
        if (!file) return true;
        if (fl.path !== file.path) return false;
        if (!section) return true;
        if (fl.line_start == null) return false;
        const ranges = flagSide(file) === 'old' ? section.old_ranges : [...section.ranges, ...section.doc_ranges];
        return rangesOverlap(fl.line_start, fl.line_end ?? fl.line_start, ranges);
    });
}

// The flags a commit's or file's card shows itself, as no row under it
// carries them: a file's whole-file flags and its line flags in none of the
// sections it lists; a commit's whole-commit flags and its flags on files it
// did not change.
export function cardFlags(flags, commit, file, sections = []) {
    if (!file) return flagsOf(flags, commit).filter(fl => fl.path == null || !commit.files.some(f => f.path === fl.path));
    return flagsOf(flags, commit, file).filter(fl => !sections.some(s => flagsOf([fl], commit, file, s).length));
}

// The flag colors, worst first, each with what it says, for hover titles,
// the popup and the summary's groups.
export const FLAG_COLORS = [['red', 'probably a problem'], ['yellow', 'a reviewer may object']];

// A reviewer's seen mark on a flag ({ reviewer, at }), or undefined.
export function seenMark(flag, reviewer) {
    return (flag.seen || []).find(m => m.reviewer === reviewer);
}

// A badge for flags: how many, seen or not, the worst color among them, and
// whether the reviewer has not seen some of them; null for none.
export function badgeOf(flags, reviewer) {
    if (!flags.length) return null;
    return {
        count: flags.length,
        color: flags.some(fl => fl.color === 'red') ? 'red' : 'yellow',
        unseen: flags.some(fl => !seenMark(fl, reviewer)),
    };
}

// A badge's hover title for flags: "1 yellow flag", "3 red flags", or "2 flags: 1 red, 1 yellow".
export function badgeTitle(flags) {
    const counts = FLAG_COLORS.map(([c]) => [c, flags.filter(fl => fl.color === c).length]).filter(([, n]) => n);
    const s = n => (n > 1 ? 's' : '');
    if (counts.length === 1) return `${counts[0][1]} ${counts[0][0]} flag${s(counts[0][1])}`;
    return `${flags.length} flags: ` + counts.map(([c, n]) => `${n} ${c}`).join(', ');
}

// The summary's flag groups, by color, red first: { color, flags }, each in
// the order the flags came in; empty groups are left out.
export function flagGroups(flags) {
    return FLAG_COLORS.map(([color]) => ({ color, flags: flags.filter(fl => fl.color === color) }))
        .filter(g => g.flags.length);
}

// Flags in commit, path and line order.
export function sortFlags(flags, commits) {
    const pos = fl => flagEntry(fl, commits)?.position ?? Infinity;
    return [...flags].sort((a, b) => pos(a) - pos(b)
        || String(a.path ?? '').localeCompare(String(b.path ?? '')) || (a.line_start ?? 0) - (b.line_start ?? 0));
}

// The flag walker's steps, for the guide bar: one flag step per flag, red
// first, then commit, path and line, its sentence as commentary. A w of
// 'f' (walk new) leaves out the flags the reviewer has seen, 'a' (walk all)
// does not, and an 'r' or 'y' after either walks the red or yellow flags
// only. The flag whose id is keep stays in, whatever the rest says.
export function walkSteps(flags, commits, reviewer, w, keep = null) {
    const color = w[1] ? FLAG_COLORS.find(([c]) => c[0] === w[1])[0] : null;
    const list = flagGroups(sortFlags(flags, commits)).flatMap(g => g.flags)
        .filter(fl => fl.id === keep || ((w[0] === 'a' || !seenMark(fl, reviewer)) && (color == null || fl.color === color)));
    return list.map(fl => ({ target: { type: 'flag', flag: fl.note_id }, highlight: [], commentary: fl.sentence, flag: fl.id }));
}

// The feedback on a flag: the reviewers' comments, by its note id.
export function flagComments(feedback, flag) {
    return feedback.filter(fb => fb.target === 'flag' && fb.flag?.note === flag.note_id);
}

// The section file feedback or a request was given on before a re-split
// took that section away, or the topic review feedback was given on before
// a topics fill took it away (a topic of '' for the entry of files not in a
// topic yet; none, with a commit, for the whole change, the entry a squashed
// iteration has before its first topics fill), as the page notes it; null
// for anything else. Feedback a retired flag left on its file or commit was
// on that flag.
export function wasOn(x) {
    if (x.flag && x.target !== 'flag') return `was on flag: ${x.flag.sentence ?? x.flag.note}`;
    if (x.target === 'review') {
        if (x.topic === '') return 'was on: not in a topic yet';
        return x.topic != null ? `was on: ${x.topic}` : x.commit != null ? 'was on: the whole change' : null;
    }
    return x.target === 'file' && x.section ? `was on: ${x.section.name}` : null;
}

export function sameSection(a, b) {
    return !!a && !!b && a.name === b.name && (a.package ?? null) === (b.package ?? null);
}

// The section a line belongs to, as { name, package }, or null.
export function sectionForLine(sections, line, side) {
    const s = sections.find(x => inRanges(line, side === 'old' ? x.old_ranges : [...x.ranges, ...x.doc_ranges]));
    return s ? { name: s.name, package: s.package ?? null } : null;
}

// The section a diff line belongs to, by the rule section diffs follow
// (standards/FORMAT.md, "Section counts"): a line with a new number goes by it;
// a removed line goes to the section whose old_ranges hold it, else to the
// section of the nearest new line in its hunk, the next one first.
export function diffLineSection(hunks, sections, line, side) {
    const live = sections.filter(s => !s.deleted);
    if (side === 'new') return sectionForLine(live, line, 'new');
    for (const h of hunks) {
        const i = h.lines.findIndex(l => l.type !== '+' && Number(l.old) === Number(line));
        if (i < 0) continue;
        if (h.lines[i].type === ' ') return sectionForLine(live, Number(h.lines[i].new), 'new');
        const held = sectionForLine(sections, line, 'old');
        if (held) return held;
        const near = h.lines.slice(i + 1).find(l => l.new != null) || h.lines.slice(0, i).findLast(l => l.new != null);
        return near ? sectionForLine(live, Number(near.new), 'new') : null;
    }
    return sectionForLine(sections, line, side);
}

// Whether feedback or a request belongs under an item's card. anchor is
// { target, commit, topic, path, section }. Line feedback belongs under no
// card: it shows only at its line. A topic's feedback shows under the topic
// of that name, from any iteration.
export function belongsTo(x, anchor) {
    if (anchor.target === 'review') return x.target === 'review';
    if (anchor.target === 'commit' && anchor.topic != null) return x.target === 'commit' && x.topic === anchor.topic;
    if (x.commit !== anchor.commit) return false;
    if (anchor.target === 'commit') return x.target === 'commit' && x.topic == null;
    if (x.path !== anchor.path) return false;
    if (anchor.target === 'file') return x.target === 'file';
    return x.target === 'section' && sameSection(x.section, anchor.section);
}

// Whether a diff's hunks show line (a number) of side ('old' or 'new').
export function lineInHunks(hunks, line, side) {
    return hunks.some(h => h.lines.some(l => l[side] != null && Number(l[side]) === Number(line)));
}

// Whether feedback or a request has no card to show under in this
// iteration (commits), so the summary lists it: by the rule belongsTo
// places it, for a commit target; for a file, section or line, when no
// commit here has that revision and path (the same head with another base or
// paths may lack the path); for a section, also when that file shows no
// section of its name (section_names: another split, or the section no
// longer changed); for a flag, when no flag of the iteration (flags) has
// its note id.
export function isAway(x, commits, flags = []) {
    if (x.target === 'review') return false;
    if (x.target === 'flag') return !flags.some(fl => fl.note_id === x.flag?.note);
    if (x.target === 'commit') return !commits.some(c => belongsTo(x, { target: 'commit', commit: c.revision, topic: c.topic ?? null }));
    const shown = f => f.path === x.path && (x.target !== 'section' || (f.section_names ?? []).some(s => sameSection(s, x.section)));
    return !commits.some(c => c.revision === x.commit && (c.files ?? []).some(shown));
}

// A commit's label: its position and subject, or its topic's name. The
// entry with no topic in an iteration that has topics holds the files not
// in one yet.
export function entryLabel(c, commits) {
    if (c.topic != null) return `${c.position}. ${c.topic}`;
    return commits.some(x => x.topic != null) ? `${c.position}. Not in a topic yet` : `${c.position}. ${c.subject}`;
}

// ---- guide ----

// Where a flag is shown: its commit, file, and line (on the file's file tab,
// or its diff tab for a deleted file; a file with no such tab, a binary one,
// shows its default tab and the flag on its card). A flag on a file its
// commit did not change shows that file whole as it is at the commit. Null
// when the flag's commit is not in the review.
export function flagPlan(flag, review) {
    const commit = flagEntry(flag, review.commits);
    if (!commit) return null;
    if (flag.path == null) return { type: 'commit', commit, panel: '' };
    const file = commit.files.find(f => f.path === flag.path);
    if (!file) return blobPlan(commit, flag.path, flag.line_start);
    if (flag.line_start == null) return { type: 'file', commit, file, panel: '' };
    const side = flagSide(file);
    return onTab({ type: 'file', commit, file, panel: side === 'old' ? 'd' : 'v', reveal: { path: file.path, side, line: flag.line_start } });
}

// Where a journal entry's link goes: its file in the last entry of the
// iteration that changed its path, on the file's default tab; null when none
// did.
export function journalPlan(entry, review) {
    const commit = review.commits.findLast(c => c.files.some(f => f.path === entry.path));
    return commit ? { type: 'file', commit, file: commit.files.find(f => f.path === entry.path), panel: '' } : null;
}

// A file plan whose panel the file has no tab for shows the file's default
// tab, with no line to reveal.
function onTab(plan) {
    if (plan.type !== 'file' || filePanels(plan.file).includes(plan.panel)) return plan;
    plan.panel = '';
    delete plan.reveal;
    return plan;
}

// A file the commit did not change, shown whole as it is at that commit.
function blobPlan(commit, path, line) {
    const plan = { type: 'blob', commit, path, panel: 'v' };
    if (line != null) plan.reveal = { path, side: 'new', line };
    return plan;
}

// A commit's tabs, as the panels they show: '' (list: its files, or a
// merge's commits), 'd' (diff; a merge changes no files of its own, so none)
// and 'r' (a merge's conflict resolution, when it has one). A commit with no
// files has neither a list nor a diff.
export function commitPanels(commit, merge) {
    const files = (commit.files ?? []).length > 0;
    return [merge || files ? '' : null, !merge && files ? 'd' : null, commit.resolution ? 'r' : null].filter(p => p != null);
}

// A file's tabs, as the panels they show: '' (list: the sections its commit
// changed), 'd' (its diff) and 'v' (the whole file after the commit). A file
// with no such sections has no list, a deleted file no whole file after the
// commit, and a binary file neither a diff nor lines to show, so no tabs.
export function filePanels(file) {
    if (file.kind === 'binary') return [];
    return [(file.section_names ?? []).length ? '' : null, 'd', file.status === 'D' ? null : 'v'].filter(p => p != null);
}

// The panel an item shows for its URL slot: the slot's own when the item has
// that tab, else its first tab, its default. '' when it has no tabs.
export function shownPanel(panels, slot) {
    return panels.includes(slot) ? slot : panels[0] ?? '';
}

// The URL slot that shows panel: '' (nothing written) for the item's first
// tab and for a panel it has no tab for, so both show its default.
export function panelSlot(panels, panel) {
    return panels.includes(panel) && panel !== panels[0] ? panel : '';
}

// The view a guide step shows: { type: 'summary' } or { type, commit, file,
// section, panel, reveal }, where section is a { name, package } selector and
// reveal the line to scroll to. A section step shows the section's diff, as
// a section expanded by hand does, so its highlight is on screen. A view step
// on a file its commit did not change gives { type: 'blob', commit, path,
// panel, reveal }. Null when the target is not in the review.
export function stepPlan(step, review) {
    const t = step.target || {};
    if (t.type === 'summary') return { type: 'summary' };
    if (t.type === 'flag') {
        const flag = review.flags.find(fl => fl.note_id === t.flag);
        return flag ? flagPlan(flag, review) : null;
    }
    const commit = entryFor(review.commits, t.commit, t.path, t.topic);
    if (!commit) return null;
    const file = t.path != null ? commit.files.find(f => f.path === t.path) : null;
    if (t.path != null && !file) return t.type === 'view' ? blobPlan(commit, t.path, t.lines?.[0]) : null;
    const section = file && t.section ? t.section : null;
    const plan = { type: section ? 'section' : file ? 'file' : 'commit', commit, file, section, panel: '' };
    if (t.type === 'diff' || (t.type === 'section' && section)) {
        plan.panel = 'd';
        const h = (step.highlight || []).find(x => !file || x.path === file.path);
        if (h) plan.reveal = { path: h.path, side: h.side, line: h.lines[0] };
        // A merge's diff is its resolution, or its list when it has none.
        const merge = !file && review.commits.some(c => c.merge_id === commit.id);
        if (merge) plan.panel = commitPanels(commit, true).includes('r') ? 'r' : '';
    }
    else if (t.type === 'view') {
        if (!file) return null;
        plan.panel = 'v';
        if (t.lines) plan.reveal = { side: 'new', line: t.lines[0] };
    }
    if (plan.reveal && !plan.reveal.path) plan.reveal.path = file.path;
    return onTab(plan);
}

// Where the guide's "next topic" and "previous topic" (or commit) go from
// step n (1-based). groups gives each step's group, the entry its target is
// on, or null for a step on none (a summary step, a target not in the
// review), which both pass over. Next is the first later step of another
// group than step n's; previous the first step of the run of steps before
// the run step n is in. Either is null when there is none.
export function topicJumps(groups, n) {
    const at = groups.map((g, i) => [g, i + 1]).filter(([g]) => g != null);
    const cur = groups[n - 1] ?? null;
    const next = at.find(([g, i]) => i > n && g !== cur)?.[1] ?? null;
    let end = at.findLastIndex(([, i]) => i < n);
    while (cur != null && end >= 0 && at[end][0] === cur) end--;
    if (end < 0) return { next, prev: null };
    let start = end;
    while (start > 0 && at[start - 1][0] === at[end][0]) start--;
    return { next, prev: at[start][1] };
}

// ---- speech ----

// Voices for the picker: on-device first, then online ones, labelled. The
// default is an on-device voice, the first matching the page language if
// any; with only online voices there is none, so the reader picks one.
export function orderVoices(voices, lang) {
    const local = voices.filter(v => v.localService);
    const online = voices.filter(v => !v.localService);
    const list = [
        ...local.map(v => ({ voice: v, label: `${v.name} (${v.lang})` })),
        ...online.map(v => ({ voice: v, label: `${v.name} (${v.lang}) (online: text leaves this machine)` })),
    ];
    const base = String(lang || '').toLowerCase().split('-')[0];
    const matches = x => String(x.voice.lang).toLowerCase().split(/[-_]/)[0] === base;
    const dflt = list.find(x => x.voice.localService && matches(x)) || list.find(x => x.voice.localService) || null;
    return { list, dflt };
}

// Agent prose as speech reads it, one sentence each: its paragraphs and
// bullets (textBlocks) with Markdown's markers gone (backticks, emphasis,
// headings, quotes, a link's target), and `::` and `->` read as a pause, so
// `Foo::Bar->new` is "Foo, Bar, new" (none where punctuation or an end is
// already). Sentences end at . ! or ? and a space; one longer than
// SPEECH_MAX is cut at ; : or , and failing that between words: Chrome's
// online voices stop an utterance at about 15 seconds, and 140 characters
// take about 13 at the slowest speed offered (0.75x).
export const SPEECH_MAX = 140;

export function speechSentences(text) {
    const lines = String(text ?? '').split('\n').map(l => l.replace(/^\s*(?:#+|>+)\s+/, ''));
    const clean = s => s
        .replace(/!?\[([^\]]*)\]\([^)]*\)/g, '$1')
        .replace(/`+/g, '')
        .replace(/(\*\*|__|\*|~~)(?=\S)(.+?)(?<=\S)\1/g, '$2')
        .replace(/(^|\s)_(?=\S)(.+?)(?<=\S)_(?=$|[\s.,;:!?)])/g, '$1$2')
        .replace(/\s*(?:::|->)\s*/g, '\u0001')
        .replace(/([.!?;:,])\u0001+/g, '$1 ')
        .replace(/\u0001+(?=[.!?;:,])/g, '')
        .replace(/^\u0001+|\u0001+$/g, '')
        .replace(/\u0001+/g, ', ')
        .replace(/\s+/g, ' ')
        .trim();
    return textBlocks(lines.join('\n'))
        .flatMap(b => (b.type === 'p' ? [b.text] : b.items))
        .flatMap(t => clean(t).split(/(?<=[.!?])\s+/))
        .flatMap(s => shortSpeech(s, /(?<=[;:,])\s+/))
        .flatMap(s => shortSpeech(s, /\s+/))
        .filter(s => /\w/.test(s));
}

// Text in pieces of at most SPEECH_MAX characters where it can be, cut
// where sep matches and packed back together up to that length.
function shortSpeech(s, sep) {
    if (s.length <= SPEECH_MAX) return [s];
    const out = [];
    for (const part of s.split(sep)) {
        if (out.length && out.at(-1).length + 1 + part.length <= SPEECH_MAX) out[out.length - 1] += ' ' + part;
        else out.push(part);
    }
    return out;
}
