// Test origin: AI
import { test } from 'node:test';
import assert from 'node:assert/strict';

import hljs from '../js/highlight/core.min.js';
import perl from '../js/highlight/perl.min.js';
import javascript from '../js/highlight/javascript.min.js';
import pageHljs from '../js/languages.js';
import {
    splitHighlighted, highlightLines, langForKind, sizeClass, orderFiles, encodeState, decodeState, encodeCommit,
    unifiedRows, splitRows, textBlocks, inlineCode, escapeHtml, inRanges,
    flagsOf, entryFor, flagEntry, flagGroups, sectionForLine, belongsTo, flagPlan, stepPlan, commitPanels, filePanels, shownPanel, panelSlot, cardFlags, orderVoices,
    commitTree, subtree, mergePath, firstLine, webUrl, diffLineSection, lineInHunks,
    isSvg, identityLine, staleReview, stepChanges, undoChanges, sortFlags, seenMark, walkSteps, wasOn, needsSplit, requestKinds, fileLabel, renameBadge, renameFact,
    isAway, entryLabel, FLAG_COLORS, badgeOf, badgeTitle, journalPlan, flagComments, speechSentences, SPEECH_MAX, topicJumps,
} from '../js/logic.js';

hljs.registerLanguage('perl', perl);
hljs.registerLanguage('javascript', javascript);

const stripTags = s => s.replace(/<[^>]*>/g, '');
const unescape = s => s.replace(/&lt;/g, '<').replace(/&gt;/g, '>').replace(/&quot;/g, '"').replace(/&#x27;/g, "'").replace(/&#39;/g, "'").replace(/&amp;/g, '&');
const balanced = s => (s.match(/<span/g) || []).length === (s.match(/<\/span>/g) || []).length;

test('renamed files show both paths and whether their content changed', () => {
    const pure = { status: 'R', path: 'b.txt', old_path: 'a.txt', size_unit: 'lines', added: 0, removed: 0, changed: 0, size_before: 5, size_after: 5 };
    const edited = { ...pure, changed: 1 };
    const plain = { status: 'M', path: 'c.txt', old_path: null, size_unit: 'lines', added: 1, removed: 0, changed: 0, size_before: 5, size_after: 6 };
    assert.equal(fileLabel(pure), 'a.txt → b.txt');
    assert.equal(fileLabel(plain), 'c.txt');
    assert.equal(renameBadge(pure), 'renamed');
    assert.equal(renameBadge(edited), 'renamed + changed');
    assert.equal(renameBadge(plain), null);
    assert.equal(needsSplit(pure), false, 'a rename alone is not split');
    assert.equal(needsSplit(edited), true);
    assert.equal(needsSplit({ ...plain, added: 0, status: 'M', size_after: 5 }), false, 'nor a mode change alone');
    assert.equal(needsSplit({ ...plain, status: 'A', added: 0 }), true, 'an added file is, even empty');
    assert.equal(needsSplit({ ...plain, status: 'D' }), false, 'a deleted file is not');
    assert.equal(needsSplit({ ...plain, size_unit: 'bytes' }), false, 'nor an image or binary file');
    assert.deepEqual(requestKinds({ type: 'file', file: edited }), ['debate', 'split'], 'a split is asked of a file the agent splits');
    assert.deepEqual(requestKinds({ type: 'file', file: pure }), ['debate'], 'not of a file only renamed: no split item would answer it');
    assert.deepEqual(requestKinds({ type: 'file', file: { ...plain, size_unit: 'bytes' } }), ['debate'], 'nor of an image or binary file');
    assert.deepEqual(requestKinds({ type: 'commit' }), ['debate'], 'other items ask for a debate only');
    assert.equal(renameFact([pure, edited, { ...edited, path: 'd.txt' }, plain]), '3 files (2 changed)', 'a commit counts its renames and the changed ones');
    assert.equal(renameFact([pure]), '1 file (0 changed)');
    assert.equal(renameFact([plain]), null, 'no renames, no fact');
});

test('wasOn names the section file feedback was given on', () => {
    assert.equal(wasOn({ target: 'file', section: { name: 'sub foo', package: 'Foo' } }), 'was on: sub foo');
    assert.equal(wasOn({ target: 'file', section: null }), null, 'feedback on the file itself');
    assert.equal(wasOn({ target: 'section', section: { name: 'sub foo' } }), null, 'feedback still on its section');
    assert.equal(wasOn({ target: 'file', flag: { note: 'n', sentence: 'Odd loop.' } }), 'was on flag: Odd loop.', 'feedback a retired flag left on its file');
    assert.equal(wasOn({ target: 'commit', flag: { note: 'n', sentence: null } }), 'was on flag: n', 'or its commit, by note id when no sentence is known');
    assert.equal(wasOn({ target: 'flag', flag: { note: 'n', sentence: 'S.' } }), null, 'feedback still on its flag');
});

test('splitHighlighted closes and reopens spans across newlines', () => {
    const lines = splitHighlighted('a<span class="x">b\nc<span class="y">d\ne</span>f\ng</span>h');
    assert.deepEqual(lines, [
        'a<span class="x">b</span>',
        '<span class="x">c<span class="y">d</span></span>',
        '<span class="x"><span class="y">e</span>f</span>',
        '<span class="x">g</span>h',
    ]);
});

test('splitHighlighted keeps empty and trailing lines', () => {
    assert.deepEqual(splitHighlighted('a\n\nb\n'), ['a', '', 'b', '']);
});

test('highlightLines over Perl with POD and a heredoc', () => {
    const src = [
        'package Foo;',
        'my $x = <<"EOT";',
        'not <code> here',
        'EOT',
        '',
        'sub bar { return "a & b" }',
        '',
        '__END__',
        '',
        '=head1 NAME',
        '',
        'Foo - thing',
        '',
        '=cut',
        '',
    ].join('\n');
    const lines = highlightLines(hljs, src, 'perl');
    const want = src.replace(/\n$/, '').split('\n');
    assert.equal(lines.length, want.length);
    lines.forEach((l, i) => {
        assert.ok(balanced(l), `line ${i + 1} balanced: ${l}`);
        assert.equal(unescape(stripTags(l)), want[i], `line ${i + 1} text`);
    });
    // The POD block is one comment span split over its lines.
    assert.match(lines[11], /hljs-comment/);
});

test('highlightLines over a JS template literal', () => {
    const src = 'const s = `a\n${b}\nc`;\nf();\n';
    const lines = highlightLines(hljs, src, 'javascript');
    assert.equal(lines.length, 4);
    assert.match(lines[2], /^<span class="hljs-string">c`<\/span>/);
    lines.forEach(l => assert.ok(balanced(l)));
});

test('highlightLines escapes unknown kinds', () => {
    assert.deepEqual(highlightLines(hljs, '<a>\nb & c\n', 'text'), ['&lt;a&gt;', 'b &amp; c']);
    assert.equal(escapeHtml(`"'`), '&quot;&#39;');
});

test('langForKind maps every file kind to a language the page registers', () => {
    const kinds = [
        'perl', 'javascript', 'typescript', 'css', 'html', 'xml', 'markdown', 'shell', 'sql', 'json', 'yaml', 'ini', 'toml',
        'python', 'ruby', 'go', 'rust', 'c', 'cpp', 'java', 'makefile', 'dockerfile', 'diff',
    ];
    for (const kind of kinds) {
        const lang = langForKind(kind);
        assert.ok(lang, `${kind} has a language`);
        assert.ok(pageHljs.getLanguage(lang), `${kind}: ${lang} is registered`);
    }
    assert.equal(langForKind('html'), 'xml');
    assert.equal(langForKind('shell'), 'bash');
    assert.equal(langForKind('toml'), 'ini');
    for (const kind of ['text', 'image', 'binary', 'cobol', 'constructor', 'toString', undefined]) assert.equal(langForKind(kind), null, `${kind} is plain`);
});

test('highlightLines over a shell script', () => {
    const src = '#!/bin/sh\nset -e\nfor f in "$@"; do\n    echo "$f" # each\ndone\n';
    const lines = highlightLines(pageHljs, src, 'shell');
    assert.equal(lines.length, 5);
    assert.match(lines[0], /hljs-meta/);
    assert.match(lines[2], /hljs-keyword">for</);
    assert.match(lines[3], /hljs-comment/);
    lines.forEach((l, i) => assert.equal(unescape(stripTags(l)), src.split('\n')[i]));
});

test('sizeClass', () => {
    assert.equal(sizeClass({ status: 'A', size_before: null, size_after: 3 }), 'added');
    assert.equal(sizeClass({ status: 'D', size_before: 3, size_after: null }), 'deleted');
    assert.equal(sizeClass({ status: 'M', size_before: 5, size_after: 3, removed: 2 }), 'changed');
    assert.equal(sizeClass({ status: 'R', size_before: 3, size_after: 5, added: 2 }), 'changed');
    assert.equal(sizeClass({ status: 'M', size_before: 3, size_after: 3, changed: 1 }), 'changed');
    assert.equal(sizeClass({ status: 'R', size_before: 3, size_after: 3, added: 0, removed: 0, changed: 0 }), '');
});

test('orderFiles', () => {
    const files = [
        { path: 'b', read_position: 1 },
        { path: 'a', read_position: 3 },
        { path: 'c', read_position: 2 },
    ];
    const paths = r => r.files.map(f => f.path);
    assert.deepEqual(paths(orderFiles(files, 'reading', 1)), ['b', 'c', 'a']);
    assert.equal(orderFiles(files, 'reading', 1).pending, false);
    assert.deepEqual(paths(orderFiles(files, 'reading', 0)), ['a', 'b', 'c']);
    assert.equal(orderFiles(files, 'reading', 0).pending, true);
    assert.deepEqual(paths(orderFiles(files, 'az', 1)), ['a', 'b', 'c']);
    assert.equal(orderFiles(files, 'az', 0).pending, false);
    assert.deepEqual(files.map(f => f.path), ['b', 'a', 'c'], 'input untouched');
});

test('state round trip', () => {
    const state = {
        it: 2,
        at: 's45',
        g: 3,
        w: 'f',
        commits: {
            3: { panel: 'd', files: {} },
            4: {
                panel: '',
                files: {
                    13: { panel: '', sections: {} },
                    12: { panel: 'd', sections: { 46: 'v', 45: '' } },
                },
            },
            5: { panel: '', files: {} },
        },
    };
    const hash = encodeState(state);
    assert.equal(hash, 'i=2&at=s45&g=3&w=f&c3=d&c4=f12~d,s45,s46~v,f13');
    const back = decodeState('#' + hash);
    assert.equal(encodeState(back), hash);
    assert.equal(back.w, 'f', 'the flag walk');
    assert.equal(decodeState('#w=a').w, 'a', 'a walk of seen flags too');
    assert.equal(decodeState('#w=fr').w, 'fr', 'a walk of one color');
    assert.equal(decodeState('#w=fg').w, null, 'no green');
    assert.equal(decodeState('#w=f4').w, null, 'no severity');
    assert.equal(encodeState(decodeState('#w=ay')), 'w=ay', 'round trip');
    assert.equal(back.commits[4].files[12].sections[46], 'v');
    assert.equal(back.commits[5], undefined, 'empty commit state dropped');
});

test('state round trip with merges and a whole-file view', () => {
    const state = {
        it: null,
        at: 'c5',
        g: null,
        commits: {
            7: { panel: '', commits: { 6: true, 4: true }, files: {} },
            6: { panel: '', commits: { 5: true }, files: {} },
            5: { panel: '', commits: {}, view: 'lib/a,b&c.pm', files: { 9: { panel: 'd', sections: {} } } },
        },
    };
    const hash = encodeState(state);
    assert.equal(hash, 'at=c5&c5=plib%2Fa%2Cb%26c.pm,f9~d&c6=c5&c7=c4,c6');
    const back = decodeState('#' + hash);
    assert.equal(encodeState(back), hash);
    assert.deepEqual(back.commits[7].commits, { 4: true, 6: true });
    assert.equal(back.commits[5].view, 'lib/a,b&c.pm');
    assert.equal(decodeState('#c1=p%E0%A4%A').commits[1], undefined, 'malformed path dropped');
    assert.deepEqual(decodeState('#c4=f12~d').commits[4].commits, {}, 'states from before merges decode');
    assert.equal(decodeState('#c7=r').commits[7].panel, 'r', 'a merge\'s resolution panel');
    assert.equal(encodeState(decodeState('#c7=r')), 'c7=r');
    assert.equal(decodeState('#c7=f3~r').commits[7], undefined, 'files take no resolution panel');
});

test('decodeState ignores junk', () => {
    const s = decodeState('#i=x&c1=zz,s9,f2~q&c2=&foo=bar&at=&g=0&w=x');
    assert.equal(s.it, null);
    assert.equal(s.g, null);
    assert.equal(s.w, null);
    assert.equal(s.at, null);
    assert.deepEqual(Object.keys(s.commits), []);
    assert.deepEqual(decodeState(''), { it: null, at: null, g: null, w: null, u: [], commits: {} });
    for (const at of ['%E0', '%', '%zz']) {
        const bad = decodeState(`#at=${at}&c1=f2`);
        assert.equal(bad.at, null, `malformed at=${at} dropped`);
        assert.deepEqual(Object.keys(bad.commits), ['1'], 'the rest survives');
    }
});

const hunks = [{
    old_start: 10, old_count: 5, new_start: 10, new_count: 4,
    lines: [
        { type: ' ', text: 'a', old: 10, new: 10 },
        { type: '-', text: 'b', old: 11 },
        { type: '-', text: 'c', old: 12 },
        { type: '-', text: 'd', old: 13 },
        { type: '+', text: 'B', new: 11 },
        { type: '+', text: 'C', new: 12 },
        { type: ' ', text: 'e', old: 14, new: 13 },
        { type: '+', text: 'f', new: 14 },
    ],
}];

test('unifiedRows', () => {
    const rows = unifiedRows(hunks);
    assert.equal(rows[0].header, '@@ -10,5 +10,4 @@');
    assert.equal(rows.length, 9);
    assert.deepEqual(rows[2], { kind: 'line', type: '-', old: 11, new: null, text: 'b' });
    assert.deepEqual(rows[5], { kind: 'line', type: '+', old: null, new: 11, text: 'B' });
});

test('splitRows pairs removals with additions', () => {
    const rows = splitRows(hunks);
    const sig = rows.slice(1).map(r => `${r.left ? r.left.type + r.left.line : '_'}|${r.right ? r.right.type + r.right.line : '_'}`);
    assert.deepEqual(sig, [' 10| 10', '-11|+11', '-12|+12', '-13|_', ' 14| 13', '_|+14']);
});

test('a unit diff names its parts', () => {
    const h = (part, start, count) => ({ part, old_start: start, old_count: count, new_start: start, new_count: count, lines: [{ type: ' ', text: 'x', old: start, new: start }] });
    const kinds = rows => rows.map(r => r.kind === 'part' ? r.label : r.kind).filter(k => k !== 'line' && k !== 'pair');
    assert.deepEqual(kinds(unifiedRows([h('code', 4, 3), h('docs', 20, 6)])), ['hunk', 'documentation — lines 20–25', 'hunk']);
    assert.deepEqual(kinds(splitRows([h('docs', 2, 1), h('code', 3, 3)])), ['documentation — line 2', 'hunk', 'code — lines 3–5', 'hunk']);
    assert.deepEqual(kinds(unifiedRows([h('docs', 2, 2), h('docs', 8, 2)])), ['documentation — lines 2–9', 'hunk', 'hunk']);
    assert.deepEqual(kinds(unifiedRows(hunks)), ['hunk'], 'a plain diff has no parts');
});

test('textBlocks and inlineCode', () => {
    assert.deepEqual(textBlocks('One\ntwo.\n\n- a\n- b\n  more\nAfter'), [
        { type: 'p', text: 'One two.' },
        { type: 'ul', items: ['a', 'b more'] },
        { type: 'p', text: 'After' },
    ]);
    assert.deepEqual(textBlocks(null), []);
    assert.deepEqual(inlineCode('call `foo()` now'), [
        { code: false, text: 'call ' }, { code: true, text: 'foo()' }, { code: false, text: ' now' },
    ]);
});

test('inRanges', () => {
    assert.ok(inRanges(5, [[1, 2], [4, 6]]));
    assert.ok(!inRanges(3, [[1, 2], [4, 6]]));
});

const fileM = { path: 'lib/Foo.pm', status: 'M' };
const fileD = { path: 'old.pm', status: 'D' };
const flags = [
    { note_id: 'n1', commit: 'c1', path: 'lib/Foo.pm', line_start: 10, line_end: 12, color: 'yellow', seen: [] },
    { note_id: 'n2', commit: 'c1', path: 'lib/Foo.pm', line_start: null, line_end: null, color: 'red', seen: [] },
    { note_id: 'n3', commit: 'c1', path: null, line_start: null, line_end: null, color: 'yellow', seen: [] },
    { note_id: 'n4', commit: 'c1', path: 'old.pm', line_start: 3, line_end: 3, color: 'red', seen: [] },
    { note_id: 'n5', commit: 'c2', path: 'lib/Foo.pm', line_start: 1, line_end: 1, color: 'red', seen: [] },
];

test('flagsOf', () => {
    const ids = l => l.map(f => f.note_id);
    const C1 = { id: 1, revision: 'c1' };
    assert.deepEqual(ids(flagsOf(flags, C1)), ['n1', 'n2', 'n3', 'n4']);
    assert.deepEqual(ids(flagsOf(flags, C1, fileM)), ['n1', 'n2']);
    const sec = { ranges: [[12, 20]], doc_ranges: [], old_ranges: [] };
    assert.deepEqual(ids(flagsOf(flags, C1, fileM, sec)), ['n1'], 'overlap at the range end; whole-file flag left out');
    assert.deepEqual(ids(flagsOf(flags, C1, fileM, { ranges: [[13, 20]], doc_ranges: [[1, 9]], old_ranges: [] })), []);
    assert.deepEqual(ids(flagsOf(flags, C1, fileD, { ranges: [], doc_ranges: [], old_ranges: [[1, 5]] })), ['n4'], 'deleted file: old side');
});

test('flag colors', () => {
    assert.deepEqual(FLAG_COLORS, [['red', 'probably a problem'], ['yellow', 'a reviewer may object']], 'worst first');
});


// Ann has seen n1 and n4.
const marked = flags.map(f => ({
    ...f,
    seen: f.note_id === 'n1' || f.note_id === 'n4' ? [{ reviewer: 'Ann', at: 5 }] : [],
}));

test('seenMark', () => {
    assert.deepEqual(seenMark(marked[0], 'Ann'), { reviewer: 'Ann', at: 5 });
    assert.equal(seenMark(marked[0], 'Bob'), undefined, 'each reviewer has their own');
    assert.equal(seenMark({}, 'Ann'), undefined, 'a flag with no marks');
});

test('badgeOf', () => {
    assert.deepEqual(badgeOf(marked, 'Ann'), { count: 5, color: 'red', unseen: true }, 'every flag, seen or not, red if any is, some unseen');
    assert.deepEqual(badgeOf([marked[0]], 'Ann'), { count: 1, color: 'yellow', unseen: false }, 'a seen flag stays counted; yellow when none is red');
    assert.deepEqual(badgeOf([marked[0], marked[3]], 'Bob'), { count: 2, color: 'red', unseen: true }, 'by the reviewer\'s own marks');
    assert.equal(badgeOf([], 'Ann'), null);
});

test('badgeTitle', () => {
    assert.equal(badgeTitle([{ color: 'yellow' }]), '1 yellow flag');
    assert.equal(badgeTitle([{ color: 'red' }, { color: 'red' }, { color: 'red' }]), '3 red flags');
    assert.equal(badgeTitle([{ color: 'yellow' }, { color: 'red' }]), '2 flags: 1 red, 1 yellow', 'red first');
});

test('flagGroups', () => {
    const ids = l => l.map(f => f.note_id);
    const groups = flagGroups(flags);
    assert.deepEqual(groups.map(g => [g.color, ids(g.flags)]), [['red', ['n2', 'n4', 'n5']], ['yellow', ['n1', 'n3']]], 'red first, order kept within a group');
    assert.deepEqual(flagGroups([]), []);
    assert.deepEqual(flagGroups([{ color: 'yellow' }]).map(g => g.color), ['yellow'], 'empty groups left out');
});

test('journalPlan', () => {
    const a1 = { path: 'a.pm' }, a2 = { path: 'a.pm' }, b = { path: 'b.pm' };
    const review = { commits: [{ id: 1, files: [a1, b] }, { id: 2, files: [a2] }, { id: 3, files: [] }] };
    assert.deepEqual(journalPlan({ path: 'a.pm' }, review), { type: 'file', commit: review.commits[1], file: a2, panel: '' }, 'the last entry that changed the path');
    assert.equal(journalPlan({ path: 'b.pm' }, review).commit.id, 1);
    assert.equal(journalPlan({ path: 'c.pm' }, review), null, 'no entry changed it: no link');
});

test('flagComments', () => {
    const fb = [{ target: 'flag', flag: { note: 'n1', sentence: 'S.' } }, { target: 'file', flag: { note: 'n1' } }, { target: 'flag', flag: { note: 'n2' } }];
    assert.deepEqual(flagComments(fb, flags[0]), [fb[0]], 'feedback on the flag by its note id; not feedback it left on its file');
});

test('sortFlags and walkSteps', () => {
    const commits = [{ revision: 'c2', position: 2 }, { revision: 'c1', position: 1 }];
    const list = [
        { id: 5, note_id: 'n5', commit: 'c2', path: 'a.pm', line_start: 1, color: 'red', sentence: 'Five.', seen: [] },
        { id: 4, note_id: 'n4', commit: 'c1', path: 'b.pm', line_start: 3, color: 'red', sentence: 'Four.', seen: [{ reviewer: 'Ann', at: 1 }, { reviewer: 'Bob', at: 1 }] },
        { id: 3, note_id: 'n3', commit: 'c1', path: 'b.pm', line_start: 1, color: 'yellow', sentence: 'Three.',
            seen: [{ reviewer: 'Ann', at: 5 }, { reviewer: 'Bob', at: 6 }] },
        { id: 2, note_id: 'n2', commit: 'c1', path: 'a.pm', line_start: 9, color: 'red', sentence: 'Two.', seen: [{ reviewer: 'Bob', at: 1 }] },
        { id: 1, note_id: 'n1', commit: 'c1', path: null, line_start: null, color: 'yellow', sentence: 'One.' },
    ];
    const ids = l => l.map(x => x.id);
    assert.deepEqual(ids(sortFlags(list, commits)), [1, 2, 3, 4, 5], 'commit, path, then line order');

    const all = walkSteps(list, commits, 'Ann', 'a');
    assert.deepEqual(all.map(x => x.flag), [2, 4, 5, 1, 3], 'red first, then commit, path and line');
    assert.deepEqual(all[0], { target: { type: 'flag', flag: 'n2' }, highlight: [], commentary: 'Two.', flag: 2 }, 'a flag step with the sentence');
    assert.deepEqual(walkSteps(list, commits, 'Ann', 'f').map(x => x.flag), [2, 5, 1], 'walk new leaves out what this reviewer has seen');
    assert.deepEqual(walkSteps(list, commits, 'Bob', 'f').map(x => x.flag), [5, 1], 'each reviewer by their own marks');
    assert.deepEqual(walkSteps(list, commits, 'Bob', 'f', 2).map(x => x.flag), [2, 5, 1], 'keeps the flag named, seen or not');
    assert.deepEqual(walkSteps(list, commits, 'Ann', 'ay').map(x => x.flag), [1, 3], 'one color');
    assert.deepEqual(walkSteps(list, commits, 'Ann', 'fr').map(x => x.flag), [2, 5], 'red ones not seen');
    assert.deepEqual(walkSteps(list, commits, 'Ann', 'fy').map(x => x.flag), [1], 'yellow ones not seen');
    const review = { flags: list, commits: [{ revision: 'c1', position: 1, files: [] }, { revision: 'c2', position: 2, files: [{ path: 'a.pm', status: 'M' }] }] };
    assert.equal(stepPlan(walkSteps(list, review.commits, 'Ann', 'a')[2], review).file.path, 'a.pm', 'steps play like guide flag steps');
});

test('sectionForLine', () => {
    const secs = [
        { name: 'a', package: 'Foo', ranges: [[1, 5]], doc_ranges: [[20, 22]], old_ranges: [] },
        { name: 'b', package: null, ranges: [], doc_ranges: [], old_ranges: [[3, 4]] },
    ];
    assert.deepEqual(sectionForLine(secs, 21, 'new'), { name: 'a', package: 'Foo' });
    assert.deepEqual(sectionForLine(secs, 3, 'old'), { name: 'b', package: null });
    assert.equal(sectionForLine(secs, 9, 'new'), null);
});

test('diffLineSection follows the section diffs\' ownership rule', () => {
    // hunks: old 10-14 -> new 10-14; old 11-13 removed, new 11-12 and 14 added.
    const secs = [
        { name: 'top', package: null, ranges: [[1, 10]], doc_ranges: [], old_ranges: [] },
        { name: 'b', package: 'Foo', ranges: [[11, 12]], doc_ranges: [], old_ranges: [] },
        { name: 'c', package: 'Foo', ranges: [[13, 20]], doc_ranges: [], old_ranges: [[12, 12]] },
        { name: 'gone', package: 'Foo', deleted: 1, ranges: [], doc_ranges: [], old_ranges: [[13, 13]] },
    ];
    const at = (line, side) => diffLineSection(hunks, secs, line, side)?.name ?? null;
    assert.equal(at(11, 'old'), 'b', 'removed line: the next new line in the hunk');
    assert.equal(at(12, 'old'), 'c', 'a unit whose old ranges held it comes first');
    assert.equal(at(13, 'old'), 'gone', 'a deleted section holds it first');
    assert.equal(at(14, 'old'), 'c', 'context line: by its new number');
    assert.equal(at(10, 'old'), 'top');
    assert.equal(at(14, 'new'), 'c');
    const tail = [{ lines: [{ type: ' ', old: 1, new: 1 }, { type: '-', old: 2 }] }];
    assert.equal(diffLineSection(tail, secs, 2, 'old').name, 'top', 'no new line after: the one before');
    assert.equal(diffLineSection([], secs, 13, 'old').name, 'gone', 'not in the hunks: old ranges');
    const json = [{ lines: [{ type: '-', old: '8', new: null }, { type: '+', old: null, new: '11' }] }];
    assert.equal(diffLineSection(json, secs, 8, 'old').name, 'b', 'line numbers as JSON strings');
});

test('belongsTo', () => {
    const sec = { name: 'bar', package: 'Foo' };
    const line = { target: 'line', commit: 'c1', path: 'p', section: sec, line: 3 };
    const fileFb = { target: 'file', commit: 'c1', path: 'p', section: null };
    assert.ok(belongsTo({ target: 'review' }, { target: 'review' }));
    assert.ok(!belongsTo(fileFb, { target: 'review' }));
    assert.ok(belongsTo({ target: 'commit', commit: 'c1' }, { target: 'commit', commit: 'c1' }));
    assert.ok(!belongsTo(fileFb, { target: 'commit', commit: 'c1' }));
    assert.ok(belongsTo(fileFb, { target: 'file', commit: 'c1', path: 'p' }));
    assert.ok(!belongsTo(line, { target: 'file', commit: 'c1', path: 'p' }), 'line feedback shows only at its line');
    assert.ok(!belongsTo(line, { target: 'section', commit: 'c1', path: 'p', section: sec }), 'not under its section either');
    const secFb = { target: 'section', commit: 'c1', path: 'p', section: sec };
    assert.ok(belongsTo(secFb, { target: 'section', commit: 'c1', path: 'p', section: { name: 'bar', package: 'Foo' } }));
    assert.ok(!belongsTo(secFb, { target: 'section', commit: 'c1', path: 'p', section: { name: 'bar', package: null } }));
    assert.ok(!belongsTo(fileFb, { target: 'section', commit: 'c1', path: 'p', section: sec }));
});

test('lineInHunks', () => {
    const hunks = [{ lines: [{ type: ' ', old: 4, new: 5 }, { type: '-', old: '5', new: null }, { type: '+', old: null, new: 6 }] }];
    assert.ok(lineInHunks(hunks, 5, 'old'), 'line numbers as JSON strings');
    assert.ok(lineInHunks(hunks, 5, 'new'));
    assert.ok(lineInHunks(hunks, 6, 'new'));
    assert.ok(!lineInHunks(hunks, 6, 'old'));
    assert.ok(!lineInHunks(hunks, 9, 'new'));
    assert.ok(!lineInHunks([], 1, 'new'));
});

const review = {
    commits: [
        { id: 1, revision: 'c1', files: [{ id: 5, path: 'lib/Foo.pm', status: 'M' }, { id: 6, path: 'old.pm', status: 'D' }] },
    ],
    flags,
};

// A squashed iteration split into topics: two entries share the head's revision.
test('topics: entries, flags, feedback and steps', () => {
    const perl = { id: 7, revision: 'h', topic: 'Perl', position: 1, files: [{ id: 70, path: 'lib/A.pm', status: 'A' }] };
    const css = { id: 8, revision: 'h', topic: 'Styles', position: 2, files: [{ id: 80, path: 'a.css', status: 'A' }] };
    const commits = [perl, css];
    assert.equal(entryFor(commits, 'h', 'a.css'), css, 'a path picks the topic holding it');
    assert.equal(entryFor(commits, 'h', null, 'Styles'), css, 'a topic picks itself');
    assert.equal(entryFor(commits, 'h', null, 'Nope'), null, 'a topic that is not there');
    assert.equal(entryFor(commits, 'h', 'README'), perl, 'a path in no topic: the first');
    assert.deepEqual(entryFor([{ revision: 'c1' }], 'c1', 'x'), { revision: 'c1' }, 'one entry per revision needs no files');

    const fls = [{ note_id: 'p', entry: 7, commit: 'h', path: 'lib/A.pm' }, { note_id: 's', entry: 8, commit: 'h', path: null }];
    assert.deepEqual(flagsOf(fls, css).map(f => f.note_id), ['s'], 'a topic has only its own flags');
    assert.equal(flagEntry(fls[1], commits), css, 'a flag finds its entry by id');
    assert.equal(flagPlan(fls[1], { commits, flags: fls }).commit, css);

    const topicFb = { target: 'commit', commit: 'old', topic: 'Styles' };
    assert.ok(belongsTo(topicFb, { target: 'commit', commit: 'h', topic: 'Styles' }), 'topic feedback shows under the topic of its name, from any iteration');
    assert.ok(!belongsTo(topicFb, { target: 'commit', commit: 'h', topic: 'Perl' }));
    assert.ok(!belongsTo(topicFb, { target: 'commit', commit: 'old' }), 'not under a commit with no topic');
    assert.equal(wasOn({ target: 'review', topic: 'Styles' }), 'was on: Styles', 'feedback moved off a topic that went');
    assert.equal(wasOn({ target: 'review', topic: null }), null);
    assert.equal(wasOn({ target: 'review', topic: null, commit: 'h' }), 'was on: the whole change', 'feedback moved off the entry before its first topics fill');
    assert.equal(wasOn({ target: 'review', topic: '', commit: 'h' }), 'was on: not in a topic yet', 'feedback moved off the files not in a topic yet');

    const r = { commits, flags: fls };
    assert.equal(stepPlan({ target: { type: 'commit', commit: 'h', topic: 'Styles' } }, r).commit, css, 'a step names its topic');
    assert.equal(stepPlan({ target: { type: 'file', commit: 'h', path: 'a.css' } }, r).file.id, 80, 'or its path does');
    assert.equal(stepPlan({ target: { type: 'commit', commit: 'h', topic: 'Gone' } }, r), null, 'a topic not in the review');
});

// Feedback with no card in this iteration is listed in the summary, by the
// same rule that places it under a card.
test('isAway', () => {
    const one = [{ revision: 'h', topic: null, files: [{ path: 'p' }] }];
    const split = [{ revision: 'h', topic: 'Perl', files: [{ path: 'q' }] }, { revision: 'h', topic: 'Styles', files: [{ path: 'p' }] }];
    const topicFb = { target: 'commit', commit: 'h', topic: 'Frontend' };
    assert.ok(isAway(topicFb, one), 'topic feedback when the same head is one entry with no topic');
    assert.ok(isAway(topicFb, split), 'topic feedback when its topic was renamed or dropped');
    assert.ok(isAway({ target: 'commit', commit: 'h', topic: null }, split), 'feedback on the whole entry once the head is split into topics');
    assert.ok(!isAway({ target: 'commit', commit: 'h', topic: 'Styles' }, split), 'not when a topic of its name is here, from any iteration');
    assert.ok(!isAway({ target: 'commit', commit: 'old', topic: 'Styles' }, split));
    assert.ok(!isAway({ target: 'commit', commit: 'h', topic: null }, one), 'nor on the entry with no topic');
    assert.ok(!isAway({ target: 'commit', commit: 'h', topic: null }, [...split, { revision: 'h', topic: null }]), 'which a topics iteration may still hold');
    assert.ok(isAway({ target: 'commit', commit: 'gone' }, one), 'a commit not here');
    assert.ok(isAway({ target: 'file', commit: 'gone', path: 'p' }, one), 'a file of one');
    assert.ok(!isAway({ target: 'line', commit: 'h', path: 'p' }, split), 'a line of a commit that is here');
    assert.ok(!isAway({ target: 'review', commit: 'gone', topic: 'X' }, one), 'review feedback is never away');
    // The same head with a new --base or --paths: the revision is here, the path not.
    const narrowed = [{ revision: 'h', topic: null, files: [{ path: 'q' }] }];
    assert.ok(isAway({ target: 'file', commit: 'h', path: 'p' }, narrowed), 'file feedback on a path the same head no longer has');
    assert.ok(isAway({ target: 'line', commit: 'h', path: 'p', line: 3, side: 'new' }, narrowed), 'line feedback too');
    assert.ok(isAway({ target: 'section', commit: 'h', path: 'p', section: { name: 'sub f' } }, narrowed), 'section feedback too');
    assert.ok(!isAway({ target: 'file', commit: 'h', path: 'q' }, narrowed), 'not on a path it still has');
    assert.ok(!isAway({ target: 'line', commit: 'h', path: 'p' }, split), 'nor on a path a topic holds');
    // A section the file no longer shows: another split, or no longer changed.
    const shown = [{ revision: 'h', topic: null, files: [{ path: 'p', section_names: [{ name: 'sub f', package: 'Foo' }] }] }];
    assert.ok(!isAway({ target: 'section', commit: 'h', path: 'p', section: { name: 'sub f', package: 'Foo' } }, shown), 'section feedback on a section shown');
    assert.ok(isAway({ target: 'section', commit: 'h', path: 'p', section: { name: 'sub g', package: 'Foo' } }, shown), 'section feedback on a section not shown');
    assert.ok(isAway({ target: 'section', commit: 'h', path: 'p', section: { name: 'sub f', package: 'Bar' } }, shown), 'its package counts');
    assert.ok(!isAway({ target: 'line', commit: 'h', path: 'p', section: { name: 'sub g' } }, shown), 'line feedback shows on its file whatever its section');
    // Feedback on a flag shows in its popup while the page shows the flag.
    const onFlag = { target: 'flag', commit: 'h', path: 'p', flag: { note: 'n1', sentence: 'S.' } };
    assert.ok(!isAway(onFlag, one, [{ note_id: 'n1' }]), 'on a flag shown');
    assert.ok(isAway(onFlag, one, [{ note_id: 'n2' }]), 'on a flag the iteration lacks, or the viewer hides');
    assert.ok(isAway(onFlag, one), 'no flags shown');
});

test('entryLabel', () => {
    const plain = { position: 1, subject: 'Land it', topic: null };
    assert.equal(entryLabel(plain, [plain]), '1. Land it', 'a commit: its subject');
    const perl = { position: 1, subject: 'Land it', topic: 'Perl' };
    const rest = { position: 2, subject: 'Land it', topic: null };
    assert.equal(entryLabel(perl, [perl, rest]), '1. Perl', 'a topic: its name');
    assert.equal(entryLabel(rest, [perl, rest]), '2. Not in a topic yet', 'the files not in a topic yet');
});

test('flagPlan', () => {
    const p = flagPlan(flags[0], review);
    assert.equal(p.type, 'file');
    assert.equal(p.file.id, 5);
    assert.equal(p.panel, 'v');
    assert.deepEqual(p.reveal, { path: 'lib/Foo.pm', side: 'new', line: 10 });
    assert.equal(flagPlan(flags[1], review).panel, '');
    assert.equal(flagPlan(flags[2], review).type, 'commit');
    assert.deepEqual([flagPlan(flags[3], review).panel, flagPlan(flags[3], review).reveal], ['d', { path: 'old.pm', side: 'old', line: 3 }]);
    assert.equal(flagPlan(flags[4], review), null, 'commit not in the review');
});

test('stepPlan', () => {
    const plan = (target, highlight) => stepPlan({ target, highlight }, review);
    assert.deepEqual(plan({ type: 'summary' }), { type: 'summary' });
    assert.equal(plan({ type: 'commit', commit: 'c1' }).type, 'commit');
    assert.equal(plan({ type: 'commit', commit: 'zz' }), null);
    assert.equal(plan({ type: 'file', commit: 'c1', path: 'nope' }), null);
    const sec = plan({ type: 'section', commit: 'c1', path: 'lib/Foo.pm', section: { name: 'bar', package: 'Foo' } }, [{ path: 'lib/Foo.pm', side: 'new', lines: [12, 14] }]);
    assert.deepEqual([sec.type, sec.file.id, sec.section.name, sec.panel], ['section', 5, 'bar', 'd'], 'a section step shows its diff');
    assert.deepEqual(sec.reveal, { path: 'lib/Foo.pm', side: 'new', line: 12 }, 'and scrolls to its highlight');
    const d = plan({ type: 'diff', commit: 'c1' }, [{ path: 'old.pm', side: 'old', lines: [4, 6] }]);
    assert.deepEqual([d.type, d.panel, d.reveal], ['commit', 'd', { path: 'old.pm', side: 'old', line: 4 }]);
    const fd = plan({ type: 'diff', commit: 'c1', path: 'lib/Foo.pm' }, [{ path: 'old.pm', side: 'old', lines: [4, 6] }]);
    assert.equal(fd.reveal, undefined, 'highlight in another file is not revealed');
    const v = plan({ type: 'view', commit: 'c1', path: 'lib/Foo.pm', lines: [7, 9] });
    assert.deepEqual([v.type, v.panel, v.reveal], ['file', 'v', { path: 'lib/Foo.pm', side: 'new', line: 7 }]);
    assert.equal(plan({ type: 'view', commit: 'c1' }), null);
    assert.equal(plan({ type: 'flag', flag: 'n1' }).panel, 'v');
    assert.equal(plan({ type: 'flag', flag: 'zz' }), null);
    const merges = {
        flags: [],
        commits: [
            { id: 7, revision: 'm7', files: [] }, { id: 8, revision: 'm8', files: [], resolution: 'x' },
            { id: 4, revision: 'c4', merge_id: 7, files: [] }, { id: 5, revision: 'c5', merge_id: 8, files: [] },
        ],
    };
    const mp = revision => stepPlan({ target: { type: 'diff', commit: revision } }, merges).panel;
    assert.equal(mp('m7'), '', 'a diff step on a merge with no resolution shows its list');
    assert.equal(mp('m8'), 'r', 'and on a merge with one, its resolution');
    assert.equal(mp('c4'), 'd', 'a commit in a merge keeps its diff');
});

test('commitPanels', () => {
    const files = [{ path: 'a.pm' }];
    assert.deepEqual(commitPanels({ files }, false), ['', 'd']);
    assert.deepEqual(commitPanels({ files: [] }, false), [], 'a commit with no files: nothing to list or diff');
    assert.deepEqual(commitPanels({ files: [] }, true), ['']);
    assert.deepEqual(commitPanels({ files: [], resolution: 'x' }, true), ['', 'r']);
});

test('filePanels', () => {
    const section_names = [{ name: 'sub f', package: 'Foo' }];
    assert.deepEqual(filePanels({ status: 'M', kind: 'perl', section_names }), ['', 'd', 'v'], 'list, diff and file');
    assert.deepEqual(filePanels({ status: 'M', kind: 'perl', section_names: [] }), ['d', 'v'], 'no sections to list: no list tab');
    assert.deepEqual(filePanels({ status: 'A', kind: 'image', section_names: [] }), ['d', 'v'], 'an image: before and after, and the picture');
    assert.deepEqual(filePanels({ status: 'D', kind: 'perl', section_names }), ['', 'd'], 'a deleted file has no file after the commit');
    assert.deepEqual(filePanels({ status: 'D', kind: 'perl', section_names: [] }), ['d'], 'nor, with no sections, a list');
    assert.deepEqual(filePanels({ status: 'M', kind: 'binary', section_names: [] }), [], 'a binary file: no tabs');
});

test("an empty panel slot shows the item's first tab", () => {
    assert.equal(shownPanel(['', 'd', 'v'], ''), '', 'the list');
    assert.equal(shownPanel(['d', 'v'], ''), 'd', 'no list: the diff');
    assert.equal(shownPanel(['d', 'v'], 'v'), 'v');
    assert.equal(shownPanel(['', 'd'], 'v'), '', 'a panel with no tab: the first');
    assert.equal(shownPanel([], 'v'), '', 'no tabs');
    assert.equal(panelSlot(['d', 'v'], 'd'), '', 'the first tab writes nothing');
    assert.equal(panelSlot(['d', 'v'], 'v'), 'v');
    assert.equal(panelSlot(['', 'd'], 'v'), '', 'nor does a panel with no tab');
    assert.equal(panelSlot(['', 'd', 'v'], 'd'), 'd');
    const plan = flagPlan(flags[1], { commits: [{ id: 1, revision: 'c1', files: [{ id: 5, path: 'lib/Foo.pm', status: 'M', section_names: [] }] }], flags });
    assert.equal(shownPanel(filePanels(plan.file), plan.panel), 'd', 'a whole-file flag on a file with no list opens its diff');
});

test('cardFlags: what no row under a card carries', () => {
    const ids = l => l.map(f => f.note_id);
    const C1 = { id: 1, revision: 'c1', files: [fileM, fileD] };
    assert.deepEqual(ids(cardFlags(flags, C1)), ['n3'], 'a commit: its whole-commit flags');
    assert.deepEqual(ids(cardFlags(flags, { ...C1, files: [fileM] })), ['n3', 'n4'], 'and flags on files it did not change');
    const sec = { ranges: [[12, 20]], doc_ranges: [], old_ranges: [] };
    assert.deepEqual(ids(cardFlags(flags, C1, fileM, [sec])), ['n2'], 'a file: its whole-file flags, not those its sections carry');
    assert.deepEqual(ids(cardFlags(flags, C1, fileM, [{ ranges: [[1, 5]], doc_ranges: [], old_ranges: [] }])), ['n1', 'n2'], 'and line flags in no section');
    assert.deepEqual(ids(cardFlags(flags, C1, fileM)), ['n1', 'n2'], 'a file with no sections: all of them');
});

test('a plan shows a file only on a tab it has', () => {
    const bin = {
        flags: [],
        commits: [{ id: 1, revision: 'c1', files: [{ id: 5, path: 'a.bin', status: 'M', kind: 'binary' }, { id: 6, path: 'old.pm', status: 'D', kind: 'perl' }] }],
    };
    const fl = flagPlan({ commit: 'c1', path: 'a.bin', line_start: 3, line_end: 3 }, bin);
    assert.deepEqual([fl.type, fl.panel, fl.reveal], ['file', '', undefined], "a line flag on a binary file shows its default tab, the flag on its card");
    const v = stepPlan({ target: { type: 'view', commit: 'c1', path: 'old.pm', lines: [2] } }, bin);
    assert.deepEqual([v.panel, v.reveal], ['', undefined], 'a view step on a deleted file shows its default tab');
    const d = stepPlan({ target: { type: 'diff', commit: 'c1', path: 'old.pm' } }, bin);
    assert.equal(d.panel, 'd', 'its diff step its diff tab');
});

test('commitTree, subtree and mergePath', () => {
    // 1 and 7 are mainline; 7 brought in 4 and the nested merge 6, which
    // brought in 5. 9 names a merge that is not in the list.
    const commits = [
        { id: 7, position: 7, merge_id: null },
        { id: 5, position: 5, merge_id: 6 },
        { id: 6, position: 6, merge_id: 7 },
        { id: 1, position: 1, merge_id: null },
        { id: 4, position: 4, merge_id: 7 },
        { id: 9, position: 9, merge_id: 99 },
    ];
    const tree = commitTree(commits);
    const ids = l => l.map(c => c.id);
    assert.deepEqual(ids(tree.mainline), [1, 7, 9]);
    assert.deepEqual(ids(tree.kids.get(7)), [4, 6]);
    assert.deepEqual(ids(tree.kids.get(6)), [5]);
    assert.equal(tree.kids.has(1), false);
    assert.deepEqual(ids(subtree(tree, tree.byId.get(7))), [7, 4, 6, 5]);
    assert.deepEqual(ids(subtree(tree, tree.byId.get(1))), [1]);
    assert.deepEqual(ids(mergePath(tree, tree.byId.get(5))), [7, 6]);
    assert.deepEqual(ids(mergePath(tree, tree.byId.get(7))), []);
    assert.deepEqual(ids(mergePath(tree, tree.byId.get(9))), []);
});

test('firstLine and isSvg', () => {
    assert.equal(firstLine('One\ntwo.\n\nThree'), 'One two.');
    assert.equal(firstLine('- a\n- b'), 'a');
    assert.equal(firstLine(null), null);
    assert.ok(isSvg('share/icon.svg') && isSvg('A.SVG') && !isSvg('svg.png') && !isSvg(null));
});

test('webUrl keeps only http and https links', () => {
    assert.equal(webUrl('https://example.com/pull/7'), 'https://example.com/pull/7');
    assert.equal(webUrl('http://example.com/'), 'http://example.com/');
    assert.equal(webUrl('javascript:alert(1)'), null);
    assert.equal(webUrl('JavaScript:alert(1)'), null);
    assert.equal(webUrl('data:text/html,x'), null);
    assert.equal(webUrl('not a url'), null);
    assert.equal(webUrl(null), null);
});

test('plans for a file its commit did not change', () => {
    const fl = { commit: 'c1', path: 'lib/Bar.pm', line_start: 4, line_end: 4 };
    assert.deepEqual(flagPlan(fl, review), {
        type: 'blob', commit: review.commits[0], path: 'lib/Bar.pm', panel: 'v', reveal: { path: 'lib/Bar.pm', side: 'new', line: 4 },
    });
    const v = stepPlan({ target: { type: 'view', commit: 'c1', path: 'lib/Bar.pm', lines: [7, 9] } }, review);
    assert.deepEqual([v.type, v.path, v.panel, v.reveal], ['blob', 'lib/Bar.pm', 'v', { path: 'lib/Bar.pm', side: 'new', line: 7 }]);
    assert.equal(stepPlan({ target: { type: 'diff', commit: 'c1', path: 'lib/Bar.pm' } }, review), null, 'only view steps');
});

test('orderVoices', () => {
    const voices = [
        { name: 'Net', lang: 'en-US', localService: false },
        { name: 'Hans', lang: 'de-DE', localService: true },
        { name: 'Ann', lang: 'en_GB', localService: true },
    ];
    const { list, dflt } = orderVoices(voices, 'en');
    assert.deepEqual(list.map(x => x.voice.name), ['Hans', 'Ann', 'Net']);
    assert.match(list[2].label, /online: text leaves this machine/);
    assert.doesNotMatch(list[0].label, /online/);
    assert.equal(dflt.voice.name, 'Ann');
    assert.equal(orderVoices(voices, 'fr').dflt.voice.name, 'Hans');
    assert.equal(orderVoices([voices[0]], 'en').dflt, null, 'never an online voice by default');
    assert.equal(orderVoices([], 'en').dflt, null);
    assert.equal(orderVoices([voices[0], voices[1]], 'en').dflt.voice.name, 'Hans', 'on-device before an online voice in the page language');
});

test('speechSentences: agent prose as speech reads it', () => {
    assert.deepEqual(speechSentences('The `Foo::Bar->new` call works. It **does** _this_ now! Is it?'),
        ['The Foo, Bar, new call works.', 'It does this now!', 'Is it?'], 'one sentence each; backticks and emphasis go; :: and -> read as a pause');
    assert.deepEqual(speechSentences('Done. `->new` builds; `$x->y` too. Ends at `Foo::`.'), ['Done.', 'new builds; $x, y too.', 'Ends at Foo.'],
        'a pause at either end of a sentence, or next to other punctuation, is dropped');
    assert.deepEqual(speechSentences('Use x, i.e., y. Or e.g., z.'), ['Use x, i.e., y.', 'Or e.g., z.'], "the author's own commas stay, so an abbreviation does not end a sentence");
    assert.deepEqual(speechSentences('Keeps snake_case_name and 2 * 3 as written.'), ['Keeps snake_case_name and 2 * 3 as written.'], 'underscores and stars inside words or alone stay');
    assert.deepEqual(speechSentences('# Head\n\nOne. Two.\n\n- an item `a`\n- a [link](https://x.example/) item\n> Quoted.'),
        ['Head', 'One.', 'Two.', 'an item a', 'a link item', 'Quoted.'], 'headings, bullets, quotes and link targets lose their markers');
    assert.deepEqual(speechSentences('Wrapped\nacross lines.'), ['Wrapped across lines.'], 'a paragraph is one run of text');
    assert.deepEqual(speechSentences(''), [], 'nothing to read');
    assert.deepEqual(speechSentences('`::` ->'), [], 'nor only markers');
    const clauses = Array.from({ length: 30 }, (_, i) => `clause ${i} of it;`).join(' ');
    const cut = speechSentences(clauses);
    assert.ok(cut.length > 1 && cut.every(x => x.length <= SPEECH_MAX && x.endsWith(';')) && cut.join(' ') === clauses, 'a long sentence is cut at its semicolons, in pieces up to the cap');
    const words = Array.from({ length: 80 }, (_, i) => `word${i}`).join(' ');
    const cutWords = speechSentences(words);
    assert.ok(cutWords.length > 1 && cutWords.every(x => x.length <= SPEECH_MAX) && cutWords.join(' ') === words, 'with no punctuation, between words');
});

test('topicJumps: the guide\'s next and previous topic', () => {
    // A summary step, three commits, a commit visited again, and a step on
    // nothing the review has.
    const g = [null, 'a', 'b', 'b', 'b', 'c', null, 'd', 'b', 'b'];
    const at = n => topicJumps(g, n);
    assert.deepEqual(at(1), { next: 2, prev: null }, 'from a summary step: the first grouped step; nothing before');
    assert.deepEqual(at(2), { next: 3, prev: null }, 'the first run has none before it');
    assert.deepEqual(at(4), { next: 6, prev: 2 }, 'mid-run: past the rest of the run; back to the start of the run before');
    assert.deepEqual(at(6), { next: 8, prev: 3 }, 'previous goes to the start of the run before, not one step back');
    assert.deepEqual(at(7), { next: 8, prev: 6 }, 'a step on nothing: the run before it is the one it follows');
    assert.deepEqual(at(8), { next: 9, prev: 6 }, 'steps on nothing are passed over');
    assert.deepEqual(at(9), { next: null, prev: 8 }, 'a guide that comes back: a later run of the same group is its own; nothing after it');
    assert.deepEqual(topicJumps(['a', 'a'], 1), { next: null, prev: null }, 'one group: nowhere to go');
});

test('identityLine', () => {
    assert.equal(identityLine({ user: 'ann', host: 'box', repo: 'Foo' }), 'ann@box · Foo');
    assert.equal(identityLine({ user: 'ann', repo: 'Foo' }), 'ann · Foo');
    assert.equal(identityLine({ host: 'box' }), 'box');
    assert.equal(identityLine({}), null);
    assert.equal(identityLine(undefined), null);
});

test('staleReview', () => {
    const now = { id: 'r2', title: 'New' };
    assert.equal(staleReview(null, now), null, 'nothing stored');
    assert.equal(staleReview('not json', now), null);
    assert.equal(staleReview(JSON.stringify({ id: 'r2', title: 'New' }), now), null, 'same review');
    const s = staleReview(JSON.stringify({ id: 'r1', title: 'Old' }), now);
    assert.deepEqual([s.was.id, s.now.id], ['r1', 'r2']);
    assert.equal(s.text, 'This tab was showing review "Old" (r1); this server is now serving review "New" (r2).');
    assert.match(staleReview(JSON.stringify({ id: 'r1' }), { id: 'r2' }).text, /review r1; .* review r2\.$/);
});

test('stepChanges records what a step changed; undoChanges puts back only that', () => {
    const reader = '#c1=d,pa.pm,f5~v,s8~d,f6&c2=d&c7=c4';
    const step = s => {
        // Opens c1's f6 diff and its section 9, closing c1's panel to show
        // it; drills c7 to c3; opens c2's f7; shows c1's file b.pm.
        s.commits[1].panel = '';
        s.commits[1].view = 'b.pm';
        s.commits[1].files[6] = { panel: 'd', sections: { 9: 'd' } };
        s.commits[7].commits[3] = true;
        s.commits[2].files[7] = { panel: '', sections: {} };
        delete s.commits[1].files[5];
    };
    const before = decodeState(reader);
    const after = decodeState(reader);
    step(after);
    const u = stepChanges(before, after);
    assert.deepEqual(u, [['c1', 'd'], ['c1f5', 'v'], ['c1f5s8', 'd'], ['c1f6', ''], ['c1f6s9', null], ['c1p', 'a.pm'], ['c2f7', null], ['c7c3', null]]);
    // The reader expands another file meanwhile; it stays.
    after.commits[2].files[8] = { panel: 'v', sections: {} };
    undoChanges(after, u);
    assert.equal(encodeState(after), 'c1=d,pa.pm,f5~v,s8~d,f6&c2=d,f8~v&c7=c4');
    assert.deepEqual(stepChanges(before, decodeState(reader)), [], 'a step that changes nothing records nothing');
    const s = decodeState('#c2=d');
    undoChanges(s, [['c1f5s8', null], ['c1f5', null]]);
    assert.equal(encodeState(s), 'c2=d', 'a slot already gone stays gone');
});

test('a step\'s changes round trip through the URL', () => {
    const state = { ...decodeState('#g=2&c1=d'), u: [['c1', 'd'], ['c1f5', ''], ['c1p', 'a,b~c.pm'], ['c7c3', null]] };
    const hash = encodeState(state);
    assert.equal(hash, 'g=2&u=c1~d,c1f5~,c1p~a%2Cb~c.pm,c7c3&c1=d');
    assert.deepEqual(decodeState('#' + hash).u, state.u);
    assert.deepEqual(decodeState('#u=x5,c1f2~%E0%A4%A,c3').u, [['c3', null]], 'bad slots and values dropped');
    assert.deepEqual(decodeState('#g=1').u, [], 'no changes');
    assert.deepEqual(decodeState('#u=c1~d%26c5%3Df9,c2~x,c1f2~r,c1f2s3~v,c4c5~d,c4c6~,c4p~,c4p~a.pm,c7~r,c7f1~').u,
        [['c1f2s3', 'v'], ['c4c6', ''], ['c4p', 'a.pm'], ['c7', 'r'], ['c7f1', '']], 'a value that does not fit its slot dropped');
});

test('encodeCommit writes only the panels the fragment carries', () => {
    const cs = { panel: 'd&c5=f9', commits: {}, files: { 3: { panel: 'x', sections: { 4: 'd,c9', 5: 'v' } } } };
    assert.equal(encodeCommit(cs), 'f3,s4,s5~v');
    assert.equal(encodeState({ ...decodeState(''), commits: { 1: cs } }), 'c1=f3,s4,s5~v');
});

test('undoChanges leaves a merged-in commit the reader closed closed', () => {
    // Merge c7 brought in merge c3, which brought in c4.
    const tree = commitTree([{ id: 1, position: 1 }, { id: 7, position: 2 }, { id: 3, position: 3, merge_id: 7 }, { id: 4, position: 4, merge_id: 3 }]);
    // The step closed c3's diff under merge c7; the reader then closed c3.
    const s = decodeState('#c7=d');
    undoChanges(s, [['c3', 'd'], ['c3f5', null], ['c3f6', 'v'], ['c1', 'd']], tree);
    assert.equal(encodeState(s), 'c1=d&c7=d', 'its slots skipped, a mainline commit put back');
    // A step that showed c7's resolution closed its drill: it is put back,
    // then what was under it.
    const t = decodeState('#c7=r');
    undoChanges(t, [['c3c4', ''], ['c4f8', 'v'], ['c7', null], ['c7c3', '']], tree);
    assert.equal(encodeState(t), 'c3=c4&c4=f8~v&c7=c3');
});

test('undoChanges closing a merged-in commit drops all under it', () => {
    const tree = commitTree([{ id: 1, position: 1 }, { id: 7, position: 2 }, { id: 3, position: 3, merge_id: 7 }, { id: 4, position: 4, merge_id: 3 }]);
    // The step opened c3 under c7; the reader then opened c4 and its file.
    const s = decodeState('#c1=d&c3=c4&c4=f8~d&c7=c3');
    undoChanges(s, [['c7c3', null]], tree);
    assert.equal(encodeState(s), 'c1=d', 'as closing c3 by hand does');
    assert.deepEqual(Object.keys(s.commits).sort(), ['1', '7']);
});

test("a commit's tab is its panel slot: list is none, the files' state kept", () => {
    const list = decodeState('#c2=f4,s5~d,f6~v');
    const diff = decodeState('#c2=d,f4,s5~d,f6~v');
    assert.equal(list.commits[2].panel, '', 'list');
    assert.equal(diff.commits[2].panel, 'd', 'diff');
    assert.deepEqual(diff.commits[2].files, list.commits[2].files, 'the list kept under the diff');
    assert.equal(encodeState(diff), 'c2=d,f4,s5~d,f6~v');
    assert.equal(encodeState(decodeState('#c7=r')), 'c7=r', 'resolution');
    // A step switching to diff records the list; undoing it goes back.
    const u = stepChanges(list, diff);
    assert.deepEqual(u, [['c2', null]]);
    undoChanges(diff, u);
    assert.equal(encodeState(diff), 'c2=f4,s5~d,f6~v');
});

test("a file's tab is its panel slot: list is none, the sections' state kept", () => {
    const list = decodeState('#c2=f4,s5~d,s7');
    const diff = decodeState('#c2=f4~d,s5~d,s7');
    const file = decodeState('#c2=f4~v,s5~d,s7');
    assert.deepEqual([list, diff, file].map(s => s.commits[2].files[4].panel), ['', 'd', 'v']);
    assert.deepEqual(diff.commits[2].files[4].sections, list.commits[2].files[4].sections, 'the sections kept under the diff');
    assert.deepEqual(file.commits[2].files[4].sections, list.commits[2].files[4].sections, 'and under the file');
    assert.equal(encodeState(file), 'c2=f4~v,s5~d,s7');
    assert.equal(encodeState(decodeState('#c2=f4~r')), '', 'a file has no resolution tab; the token is dropped');
    // A step switching to the file tab records the list; undoing it goes back.
    const u = stepChanges(list, file);
    assert.deepEqual(u, [['c2f4', '']]);
    undoChanges(file, u);
    assert.equal(encodeState(file), 'c2=f4,s5~d,s7');
});
