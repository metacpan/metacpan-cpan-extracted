CREATE TABLE IF NOT EXISTS entry (
    slug    TEXT PRIMARY KEY,
    dir     TEXT NOT NULL UNIQUE
) WITHOUT ROWID;

CREATE TABLE IF NOT EXISTS lock (
    pid         INTEGER,
    start_time  INTEGER NOT NULL,
    slug        TEXT NOT NULL,
    exclusive   INTEGER,
    PRIMARY KEY (pid, slug),
    FOREIGN KEY (slug) REFERENCES entry (slug) ON DELETE CASCADE
) WITHOUT ROWID;

INSERT OR IGNORE INTO entry (slug, dir) VALUES ('__LISTING__', 'RESERVED');
