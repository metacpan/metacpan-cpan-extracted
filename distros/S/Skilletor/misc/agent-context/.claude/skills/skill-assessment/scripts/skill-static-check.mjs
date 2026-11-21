#!/usr/bin/env node
// Static checks for skills, agents and rules — the mechanical half of the
// skill-assessment rubric (criteria A5, B7, B8, B11, C3, E2, E3, E4, F1).
//
//   node skill-static-check.mjs [--inventory] [--home <dir>] <path>...
//
// A path may be a SKILL.md, an agent/rule .md, a skill directory, a skills/,
// agents/ or rules/ directory, or a
// directory holding skills/, agents/, rules/ (a .claude dir or a skilletor
// source). Eval suites (`evals/`, a case dir, `graders/`) are checked as eval
// files — prompt body present, grader `type:` set — never as skills. One line
// per finding: "<path>: ERROR|WARN: <message>". Exit 1 when any ERROR was found. No dependencies; Node >= 18.
import { readFileSync, statSync, readdirSync, existsSync } from "node:fs";
import { homedir } from "node:os";
import { basename, dirname, join, resolve } from "node:path";

const DESCRIPTION_MAX_CHARS = 1024; // ~200–250 tokens: the trigger budget the docs recommend
const SKILL_BODY_MAX_LINES = 150;   // skill-authoring: progressive disclosure beyond this
const RULES_MAX_LINES = 90;         // loaded on every turn
const AGENT_BODY_MAX_LINES = 60;    // a body longer than this is restating a skill
const TIME_SENSITIVE = /\b(20\d\d-\d\d(-\d\d)?|recently|currently|the new (api|version|way)|as of (20\d\d|now|today)|v?\d+\.\d+\.\d+)\b/i;
const PLEADING = /\b(MANDATORY|CRITICAL|IMPORTANT|ALWAYS|NEVER)\b:|\bload (the )?[\w:-]+ (skill )?first\b/;
const AUDIT_ROLE = /\b(audit|auditor|review|reviewer|report|checker|assess|assessor)\b/i;

const args = process.argv.slice(2);
let inventory = false;
let home = homedir();
const paths = [];
for (let i = 0; i < args.length; i++) {
  if (args[i] === "--inventory") inventory = true;
  else if (args[i] === "--home") home = args[++i];
  else paths.push(args[i]);
}
if (paths.length === 0) {
  console.error("usage: skill-static-check.mjs [--inventory] [--home <dir>] <path>...");
  process.exit(2);
}

const cwd = process.cwd();
let errors = 0;
const findings = [];
const report = (file, level, msg) => { if (level === "ERROR") errors++; findings.push(`${file}: ${level}: ${msg}`); };

function splitFrontmatter(text) {
  const m = /^---\r?\n([\s\S]*?)\r?\n---\r?\n?([\s\S]*)$/.exec(text);
  return m ? { fm: m[1], body: m[2], hasFm: true } : { fm: "", body: text, hasFm: false };
}
// Minimal YAML: top-level "key: value", nested "briefing:\n  skills:\n    - x", flow lists.
function fmValue(fm, key) {
  const m = new RegExp(`^${key}:[ \\t]*(.*)$`, "m").exec(fm);
  if (!m) return undefined;
  let v = m[1].trim();
  if (v.startsWith(">") || v.startsWith("|")) {
    const lines = [];
    const rest = fm.slice(m.index + m[0].length).split(/\r?\n/);
    for (const l of rest) { if (/^\s+\S/.test(l)) lines.push(l.trim()); else if (l.trim() === "") continue; else break; }
    return lines.join(" ");
  }
  if ((v.startsWith('"') && v.endsWith('"')) || (v.startsWith("'") && v.endsWith("'"))) v = v.slice(1, -1);
  return v;
}
function listValue(fm, key) {
  const flow = new RegExp(`^${key}:[ \\t]*\\[([^\\]]*)\\]`, "m").exec(fm);
  if (flow) return flow[1].split(",").map((s) => s.trim()).filter(Boolean);
  const block = new RegExp(`^${key}:[ \\t]*\\n((?:[ \\t]+-[ \\t]*[^\\n]+\\n?)+)`, "m").exec(fm);
  if (block) return block[1].split(/\n/).map((l) => l.replace(/^\s*-\s*/, "").trim()).filter(Boolean);
  const inline = fmValue(fm, key);
  return inline ? inline.split(",").map((s) => s.trim()).filter(Boolean) : [];
}
function briefingSkills(fm) {
  const m = /^briefing:[ \t]*\n((?:[ \t]+[^\n]*\n?)+)/m.exec(fm);
  if (!m) return null;
  const block = m[1].replace(/^[ \t]{2}/gm, "");
  return listValue(block, "skills");
}
// Project root of a file: the parent of the nearest `.claude` ancestor, else cwd.
function projectRootOf(file) {
  const parts = resolve(file).split("/");
  const i = parts.lastIndexOf(".claude");
  return i > 0 ? parts.slice(0, i).join("/") : cwd;
}
function resolveSkill(name, projectRoot) {
  const candidates = [];
  if (name.includes(":")) {
    const [plugin, skill] = name.split(":");
    candidates.push(join(home, ".claude/plugins/cache", plugin, "skills", skill, "SKILL.md"));
    for (const mk of safeReaddir(join(home, ".claude/plugins/cache")))
      candidates.push(join(home, ".claude/plugins/cache", mk, plugin, "skills", skill, "SKILL.md"));
  }
  candidates.push(join(projectRoot, ".claude/skills", name, "SKILL.md"), join(home, ".claude/skills", name, "SKILL.md"));
  const cache = join(home, ".claude/plugins/cache");
  for (const mk of safeReaddir(cache)) {
    candidates.push(join(cache, mk, "skills", name, "SKILL.md"));
    for (const pl of safeReaddir(join(cache, mk))) {
      candidates.push(join(cache, mk, pl, "skills", name, "SKILL.md"));
      for (const ver of safeReaddir(join(cache, mk, pl))) candidates.push(join(cache, mk, pl, ver, "skills", name, "SKILL.md"));
    }
  }
  return candidates.some((p) => existsSync(p));
}
function safeReaddir(dir) { try { return readdirSync(dir); } catch { return []; } }

function classify(file) {
  const parts = resolve(file).split("/");
  if (basename(file) === "SKILL.md") return "skill";
  if (basename(dirname(file)) === "graders") return "eval-grader";
  if (basename(file) === "prompt.md" && (existsSync(join(dirname(file), "graders")) || parts.includes("evals"))) return "eval-prompt";
  if (parts.includes("agents")) return "agent";
  if (parts.includes("rules")) return "rule";
  return "unknown";
}

function checkLinks(file, body, type) {
  const dir = dirname(file);
  for (const m of body.matchAll(/\]\(([^)\s#]+)(?:#[^)]*)?\)/g)) {
    const target = m[1];
    if (/^[a-z]+:\/\//.test(target)) continue;
    const full = resolve(dir, target);
    if (!existsSync(full)) { report(file, "ERROR", `link does not resolve: ${target}`); continue; }
    if (type === "skill" && /\.md$/.test(target) && target.includes("/")) {
      // one level deep: a referenced file must not link further into references/
      const sub = readFileSync(full, "utf8");
      const chained = [...sub.matchAll(/\]\(([^)\s#]+\.md)(?:#[^)]*)?\)/g)].map((x) => x[1]).filter((t) => !/^[a-z]+:\/\//.test(t) && !t.startsWith("../"));
      if (chained.length) report(file, "WARN", `chained reference: ${target} links on to ${chained.join(", ")}`);
    }
  }
}

function checkFile(file) {
  const type = classify(file);
  const text = readFileSync(file, "utf8");
  const { fm, body, hasFm } = splitFrontmatter(text);
  const bodyLines = body.split(/\r?\n/).length;
  const name = fmValue(fm, "name");
  const description = fmValue(fm, "description") ?? "";
  if (inventory) {
    findings.push(`${file}\t${type}\t${bodyLines} lines\t${Buffer.byteLength(text)} B\tdescription ${description.length} chars`);
  }
  if (type === "eval-grader" || type === "eval-prompt") {
    // plugin-eval case files: frontmatter drives the runner, there is no router to judge
    if (type === "eval-grader" && !fmValue(fm, "type")) report(file, "ERROR", "grader has no 'type:' (tool_used, llm, regex, file_exists …)");
    if (!body.trim() && (type === "eval-prompt" || fmValue(fm, "type") === "llm")) report(file, "ERROR", `empty body — the ${type === "eval-prompt" ? "prompt" : "llm grader"} has nothing to say`);
    return { type, name: basename(file), description: "" };
  }
  if (type === "rule") {
    if (bodyLines > RULES_MAX_LINES) report(file, "WARN", `rules file is ${bodyLines} lines (budget ~${RULES_MAX_LINES}, loaded every turn)`);
    const ruleProse = body.replace(/`[^`\n]*`/g, "").replace(/\S*\/\S*/g, "");
    if (TIME_SENSITIVE.test(ruleProse)) report(file, "WARN", `time-sensitive wording: ${TIME_SENSITIVE.exec(ruleProse)[0]}`);
    return { type, name: basename(file, ".md"), description: "" };
  }
  if (!hasFm) { report(file, "ERROR", "no frontmatter"); return { type, name: basename(file), description: "" }; }
  if (!description) report(file, "ERROR", "description missing");
  else {
    if (description.length > DESCRIPTION_MAX_CHARS) report(file, "ERROR", `description ${description.length} chars (budget ${DESCRIPTION_MAX_CHARS}) — the router is truncated in listings`);
    if (type === "skill" && !/\b(use when|use for|use (it|this) when|invoke when|when)\b/i.test(description)) report(file, "WARN", "description does not state a trigger condition (A1/A2: 'Use when …')");
    if (type === "skill" && /^\s*(scaffolds|generates|creates|builds|runs|writes|converts)\b/i.test(description)) report(file, "WARN", "description opens with a process verb — it summarises how, not when (A1)");
  }
  if (type === "skill") {
    const dirName = basename(dirname(file));
    if (name && name !== dirName) report(file, "ERROR", `name '${name}' differs from directory '${dirName}'`);
    if (bodyLines > SKILL_BODY_MAX_LINES) report(file, "WARN", `body ${bodyLines} lines (budget ~${SKILL_BODY_MAX_LINES}; move material to references/)`);
    const allowed = new Set(["name", "description", "allowed-tools", "disable-model-invocation", "user-invocable", "context", "arguments", "model", "license", "metadata", "compatibility"]);
    for (const k of fm.match(/^[\w-]+(?=:)/gm) ?? []) if (!allowed.has(k)) report(file, "WARN", `unknown frontmatter key '${k}' (Claude Code may reject the skill)`);
  }
  if (type === "agent") {
    const stem = basename(file, ".md");
    if (name !== stem) report(file, "ERROR", `name '${name}' differs from filename stem '${stem}'`);
    if (/^allowed-tools:/m.test(fm)) report(file, "ERROR", "'allowed-tools' is not an agent field — Claude Code ignores it silently; use 'tools:' (the agent currently inherits every tool)");
    if (/^skills:/m.test(fm) && !briefingSkills(fm)) report(file, "WARN", "top-level 'skills:' — native preload; the briefing plugin only reads 'briefing.skills' and does not hard-fail on this key");
    const tools = listValue(fm, "tools");
    if (AUDIT_ROLE.test(description) && !/\b(fix|implement|write|edit)\b/i.test(description) && (tools.length === 0 || tools.some((t) => /^(Edit|Write|MultiEdit|NotebookEdit)$/.test(t))))
      report(file, "WARN", "audit/report role but Edit/Write available (E4) — an auditor that can edit starts fixing");
    const skills = briefingSkills(fm);
    if (skills === null) report(file, "WARN", "no briefing.skills block — the agent runs unbriefed");
    else for (const s of skills) if (!resolveSkill(s, projectRootOf(file))) report(file, "ERROR", `briefing skill does not resolve: ${s} (the spawn will be denied)`);
    if (bodyLines > AGENT_BODY_MAX_LINES) report(file, "WARN", `agent body ${bodyLines} lines — check it is not restating briefed skills (E5)`);
    if (!/non-negotiable/.test(body)) report(file, "WARN", "body lacks the 'conventions are non-negotiable — apply silently' close");
  }
  const prose = body.replace(/```[\s\S]*?```/g, "").replace(/`[^`\n]*`/g, "").replace(/\S*\/\S*/g, ""); // no code spans, no paths
  if (TIME_SENSITIVE.test(prose) && !/old patterns/i.test(body)) report(file, "WARN", `time-sensitive wording (B7): '${TIME_SENSITIVE.exec(prose)[0]}'`);
  if (PLEADING.test(body)) report(file, "WARN", `pleading/shouting (B11): '${PLEADING.exec(body)[0]}'`);
  checkLinks(file, body, type);
  return { type, name: name ?? basename(file), description };
}

function collect(p) {
  const st = statSync(p);
  if (st.isFile()) return [p];
  const out = [];
  const skillMd = join(p, "SKILL.md");
  if (existsSync(skillMd)) return [skillMd];
  const isCase = (d) => existsSync(join(d, "prompt.md")) || existsSync(join(d, "graders"));
  const caseFiles = (d) => [join(d, "prompt.md"), ...safeReaddir(join(d, "graders")).filter((e) => e.endsWith(".md")).map((e) => join(d, "graders", e))].filter((f) => existsSync(f));
  if (isCase(p)) return caseFiles(p);
  if (basename(p) === "graders") return safeReaddir(p).filter((e) => e.endsWith(".md")).map((e) => join(p, e));
  if (basename(p) === "evals") return safeReaddir(p).map((e) => join(p, e)).filter((d) => statSync(d).isDirectory() && isCase(d)).flatMap(caseFiles);
  const typeDirs = ["skills", "agents", "rules"];
  // p is itself a type dir (.claude/rules, a source's skills/) or holds them
  for (const [sub, d] of typeDirs.includes(basename(resolve(p))) ? [[basename(resolve(p)), p]] : typeDirs.map((t) => [t, join(p, t)])) {
    if (!existsSync(d)) continue;
    for (const e of readdirSync(d)) {
      const f = join(d, e);
      if (sub === "skills") { const s = join(f, "SKILL.md"); if (existsSync(s)) out.push(s); }
      else if (e.endsWith(".md")) out.push(f);
    }
  }
  if (out.length === 0) for (const e of readdirSync(p)) if (e.endsWith(".md")) out.push(join(p, e));
  return out;
}

const items = [];
for (const p of paths) for (const f of collect(p)) { const r = checkFile(f); if (r) items.push({ file: f, ...r }); }

// A6: sibling skills sharing distinctive trigger terms
const skills = items.filter((i) => i.type === "skill");
const terms = (d) => new Set((d.toLowerCase().match(/[a-z][a-z0-9.-]{4,}/g) ?? []).filter((w) => !STOP.has(w)));
const STOP = new Set(["skill", "skills", "agent", "agents", "claude", "when", "using", "before", "after", "their", "which", "about", "these", "those", "files", "file", "project", "projects", "with", "from", "into", "that", "this", "also", "should", "would", "could", "every", "other", "there", "where", "while", "being", "have", "has", "does", "rule", "rules", "code", "getty", "getty's", "repo", "repos", "existing", "adding", "editing", "writing", "checking"]);
for (let i = 0; i < skills.length; i++) for (let j = i + 1; j < skills.length; j++) {
  const a = terms(skills[i].description), b = terms(skills[j].description);
  const shared = [...a].filter((w) => b.has(w));
  if (shared.length >= 4) report(skills[i].file, "WARN", `shares ${shared.length} trigger terms with ${skills[j].name} (A6): ${shared.slice(0, 6).join(", ")}`);
}

for (const l of findings) console.log(l);
if (!inventory) console.log(`${items.length} item(s) checked, ${errors} error(s), ${findings.length - errors} warning(s)`);
process.exit(errors ? 1 : 0);
