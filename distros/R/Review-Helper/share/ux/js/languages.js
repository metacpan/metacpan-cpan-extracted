// highlight.js with every language the page highlights registered: the
// languages langForKind (logic.js) maps file kinds to.
import hljs from './highlight/core.min.js';
import perl from './highlight/perl.min.js';
import javascript from './highlight/javascript.min.js';
import css from './highlight/css.min.js';
import xml from './highlight/xml.min.js';
import markdown from './highlight/markdown.min.js';
import bash from './highlight/bash.min.js';
import sql from './highlight/sql.min.js';
import json from './highlight/json.min.js';
import yaml from './highlight/yaml.min.js';
import ini from './highlight/ini.min.js';
import python from './highlight/python.min.js';
import go from './highlight/go.min.js';
import diff from './highlight/diff.min.js';
import plaintext from './highlight/plaintext.min.js';
import ruby from './highlight/ruby.min.js';
import rust from './highlight/rust.min.js';
import c from './highlight/c.min.js';
import cpp from './highlight/cpp.min.js';
import java from './highlight/java.min.js';
import typescript from './highlight/typescript.min.js';
import dockerfile from './highlight/dockerfile.min.js';
import makefile from './highlight/makefile.min.js';

const LANGUAGES = {
    perl, javascript, css, xml, markdown, bash, sql, json, yaml, ini, python, go, diff, plaintext, ruby, rust, c, cpp, java, typescript, dockerfile, makefile,
};
for (const [name, lang] of Object.entries(LANGUAGES)) hljs.registerLanguage(name, lang);

export default hljs;
