CREATE TABLE meta (
    key   TEXT PRIMARY KEY,
    value TEXT NOT NULL
);
-- Required keys: format = 'review-file', format_version = '1',
-- generator = '<tool name> <version>'.

CREATE TABLE review (
    id      TEXT    PRIMARY KEY,               -- UUID v7
    title   TEXT,
    source  TEXT,                              -- pull/merge request URL, when reviewing one
    created INTEGER NOT NULL,
    state   TEXT    NOT NULL CHECK (state IN ('open', 'closed'))
);  -- exactly one row

CREATE TABLE iteration (
    number  INTEGER PRIMARY KEY,               -- 1, 2, ...
    base    TEXT    NOT NULL,                  -- revision id; the empty revision for a whole codebase
    head    TEXT    NOT NULL,                  -- revision id
    squashed INTEGER NOT NULL DEFAULT 0,       -- 1: one combined entry for base..head
    paths   TEXT,                              -- JSON array of VCS path specs limiting the review; NULL = all
    pin     TEXT    NOT NULL,                  -- the pin keeping head alive
    created INTEGER NOT NULL,
    note    TEXT,                              -- what this iteration changed
    what    TEXT,                              -- agent summary of the whole change
    why     TEXT,
    how     TEXT
);

CREATE TABLE commit_entry (
    id        INTEGER PRIMARY KEY,
    iteration INTEGER NOT NULL REFERENCES iteration (number),
    position  INTEGER NOT NULL,                -- 1 = first commit
    merge_id  INTEGER REFERENCES commit_entry (id),  -- the merge that brought it in; NULL on the mainline
    revision  TEXT    NOT NULL,                -- the commit's revision id
    parent    TEXT,                            -- first parent's revision id; NULL for a root commit
    subject   TEXT    NOT NULL,
    message   TEXT    NOT NULL,
    author    TEXT,
    authored  INTEGER,
    change_id TEXT,                            -- the VCS's stable id of the change (git: patch-id --stable)
    topic     TEXT,                            -- squashed iterations: the topic's name; NULL: no topic
    what      TEXT,
    why       TEXT,
    how       TEXT,
    order_set INTEGER NOT NULL DEFAULT 0,      -- 1 once reading order is filled
    UNIQUE (iteration, position)
);

CREATE UNIQUE INDEX commit_entry_revision ON commit_entry (iteration, revision, IFNULL(topic, ''));

CREATE TABLE file_change (
    id            INTEGER PRIMARY KEY,
    commit_id     INTEGER NOT NULL REFERENCES commit_entry (id),
    path          TEXT    NOT NULL,            -- path after the commit (before, for deletes)
    old_path      TEXT,                        -- renames only
    status        TEXT    NOT NULL CHECK (status IN ('A', 'D', 'M', 'R')),
    kind          TEXT    NOT NULL,            -- perl, javascript, typescript, css, html, xml,
                                               -- markdown, shell, sql, json, yaml, ini, toml, python,
                                               -- ruby, go, rust, c, cpp, java, makefile, dockerfile,
                                               -- diff, text, image, binary
    size_unit     TEXT    NOT NULL CHECK (size_unit IN ('lines', 'bytes')),
    size_before   INTEGER,                     -- NULL when added
    size_after    INTEGER,                     -- NULL when deleted
    added         INTEGER NOT NULL DEFAULT 0,
    removed       INTEGER NOT NULL DEFAULT 0,
    changed       INTEGER NOT NULL DEFAULT 0,
    read_position INTEGER,                     -- reading order; NULL until filled
    split_source  TEXT    NOT NULL CHECK (split_source IN ('none', 'agent')),
    what          TEXT,
    object_system TEXT,
    paradigms     TEXT,
    UNIQUE (commit_id, path)
);

CREATE TABLE section (
    id         INTEGER PRIMARY KEY,
    file_id    INTEGER NOT NULL REFERENCES file_change (id),
    position   INTEGER NOT NULL,               -- file order
    name       TEXT    NOT NULL,               -- section name
    package    TEXT,                           -- enclosing package/class/module, when known
    ranges     TEXT    NOT NULL,               -- JSON range list, new side; [] when deleted
    doc_ranges TEXT    NOT NULL DEFAULT '[]',  -- JSON range list, new side
    old_ranges TEXT    NOT NULL DEFAULT '[]',  -- JSON range list, old side; units
    deleted    INTEGER NOT NULL DEFAULT 0,
    added      INTEGER NOT NULL DEFAULT 0,
    removed    INTEGER NOT NULL DEFAULT 0,
    changed    INTEGER NOT NULL DEFAULT 0,
    what       TEXT
);

CREATE INDEX section_file ON section (file_id, position);

CREATE TABLE flag (
    id              INTEGER PRIMARY KEY,
    note_id         TEXT    NOT NULL,          -- journal note id; shared by carried-forward copies
    commit_id       INTEGER NOT NULL REFERENCES commit_entry (id),
    path            TEXT,                      -- NULL: whole commit
    line_start      INTEGER,                   -- NULL: whole file
    line_end        INTEGER,
    color           TEXT    NOT NULL CHECK (color IN ('yellow', 'red')),
    color_reason    TEXT,                      -- why the color last changed; NULL: as recorded
    kind            TEXT    NOT NULL CHECK (kind IN ('deviation', 'assumption', 'self-review', 'test-revealed', 'note', 'other')),
    sentence        TEXT    NOT NULL,
    detail          TEXT,
    created         INTEGER NOT NULL,
    pending         INTEGER NOT NULL DEFAULT 0  -- 1: made pending by the carry-forward, awaiting the agent
);

CREATE TABLE journal_entry (
    id        TEXT    PRIMARY KEY,             -- the journal note's id
    iteration INTEGER NOT NULL REFERENCES iteration (number),
    kind      TEXT    NOT NULL CHECK (kind IN ('deviation', 'assumption', 'self-review', 'test-revealed', 'note', 'other')),
    path      TEXT    NOT NULL,
    unit      TEXT,
    sentence  TEXT    NOT NULL,
    detail    TEXT,
    created   INTEGER NOT NULL
);  -- the agent's notes for the reviewer's information, not flags

CREATE TABLE guide_step (
    iteration  INTEGER NOT NULL REFERENCES iteration (number),
    position   INTEGER NOT NULL,
    target     TEXT    NOT NULL,               -- JSON; see "Guide JSON" in FORMAT.md
    highlight  TEXT    NOT NULL DEFAULT '[]',  -- JSON; see "Guide JSON" in FORMAT.md
    commentary TEXT    NOT NULL,
    PRIMARY KEY (iteration, position)
);

CREATE TABLE feedback (
    id              INTEGER PRIMARY KEY,
    iteration       INTEGER NOT NULL REFERENCES iteration (number),
    target          TEXT    NOT NULL CHECK (target IN ('review', 'commit', 'file', 'section', 'line', 'flag')),
    revision        TEXT,                      -- the commit's revision id
    path            TEXT,
    section_name    TEXT,
    section_package TEXT,
    topic           TEXT,                      -- commit targets: the topic of a squashed iteration
    flag            TEXT,                      -- flag targets: the flag's note id
    flag_sentence   TEXT,                      -- with flag: that flag's sentence
    line            INTEGER,
    side            TEXT    CHECK (side IN ('old', 'new')),
    body            TEXT    NOT NULL,
    created         INTEGER NOT NULL,
    updated         INTEGER NOT NULL,
    status          TEXT    NOT NULL CHECK (status IN ('open', 'addressed', 'declined')),
    response        TEXT,
    resolved_in     INTEGER,                   -- iteration number
    published       INTEGER,                   -- when posted to the pull/merge request; NULL if not
    reviewer        TEXT                       -- who wrote it: 'Name <email>' or a login name; NULL if unknown
);

CREATE TABLE request (
    id              INTEGER PRIMARY KEY,
    iteration       INTEGER NOT NULL REFERENCES iteration (number),
    kind            TEXT    NOT NULL CHECK (kind IN ('debate', 'split')),
    target          TEXT    NOT NULL CHECK (target IN ('review', 'commit', 'file', 'section')),
    revision        TEXT,                      -- the commit's revision id
    path            TEXT,
    section_name    TEXT,
    section_package TEXT,
    topic           TEXT,                      -- commit targets: the topic of a squashed iteration
    note            TEXT,                      -- the human's note
    status          TEXT    NOT NULL CHECK (status IN ('open', 'done')),
    created         INTEGER NOT NULL,
    case_for        TEXT,                      -- debate results
    case_against    TEXT,
    reviewer        TEXT                       -- who asked, as in feedback
);

CREATE TABLE flag_seen (
    flag     INTEGER NOT NULL REFERENCES flag (id),
    reviewer TEXT    NOT NULL,                 -- as in feedback
    at       INTEGER NOT NULL,                 -- when marked
    PRIMARY KEY (flag, reviewer)
);  -- a reviewer has seen the flag
