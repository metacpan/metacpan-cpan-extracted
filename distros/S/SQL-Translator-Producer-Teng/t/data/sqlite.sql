CREATE TABLE branch (
  branch_id INTEGER PRIMARY KEY NOT NULL,
  project VARCHAR(255) NOT NULL,
  branch VARCHAR(255) NOT NULL,
  last_report_id INTEGER,
  ctime DATETIME NOT NULL
);

CREATE UNIQUE INDEX project_branch_uniq ON branch (project, branch);

CREATE TABLE report (
  report_id INTEGER PRIMARY KEY NOT NULL,
  branch_id INTEGER NOT NULL,
  status TINYINT NOT NULL,
  repo TEXT,
  revision VARCHAR(255),
  vc_log TEXT,
  body TEXT,
  ctime DATETIME NOT NULL,
  FOREIGN KEY (branch_id) REFERENCES branch(branch_id) ON DELETE CASCADE
);
