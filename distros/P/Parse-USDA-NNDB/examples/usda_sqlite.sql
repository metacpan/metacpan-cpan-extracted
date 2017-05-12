CREATE TABLE food_des (
    ndb_no      TEXT NOT NULL PRIMARY KEY,
    fdgrp_cd    TEXT NOT NULL,
    long_desc   TEXT NOT NULL,
    shrt_desc   TEXT NOT NULL,
    comname     TEXT,
    manufacname TEXT,
    survey      INTEGER,
    ref_desc    TEXT,
    refuse      INTEGER,
    sciname     TEXT,
    n_factor    REAL,
    pro_factor  REAL,
    fat_factor  REAL,
    cho_factor  REAL,
    FOREIGN KEY(fdgrp_cd) REFERENCES fd_group(fdgrp_cd)
);

CREATE TABLE fd_group (
    fdgrp_cd   TEXT NOT NULL PRIMARY KEY,
    fdgrp_desc TEXT NOT NULL
);

CREATE TABLE langual (
    ndb_no      TEXT NOT NULL,
    factor_code TEXT NOT NULL,
    PRIMARY KEY (ndb_no, factor_code),
    FOREIGN KEY(ndb_no) REFERENCES food_des(ndb_no),
    FOREIGN KEY(factor_code) REFERENCES langdesc(factor_code)
);
CREATE INDEX ndb_factor ON langual (ndb_no, factor_code);

CREATE TABLE langdesc (
    factor_code TEXT NOT NULL PRIMARY KEY,
    description TEXT NOT NULL
);

CREATE TABLE nut_data (
    ndb_no        TEXT NOT NULL,
    nutr_no       TEXT NOT NULL,
    nutr_val      REAL NOT NULL,
    num_data_pts  INTEGER NOT NULL,
    std_err       REAL,
    src_cd        TEXT NOT NULL,
    deriv_cd      TEXT,
    ref_ndb_no    TEXT,
    add_nutr_mark TEXT,
    num_studies   INTEGER,
    min           REAL,
    max           REAL,
    df            INTEGER,
    low_eb        REAL,
    up_eb         REAL,
    stat_cmt      TEXT,
    addmod_date   TEXT,
    cc            TEXT,
    PRIMARY KEY  (ndb_no, nutr_no),
    FOREIGN KEY(ndb_no)   REFERENCES food_des(ndb_no),
    FOREIGN KEY(nutr_no)  REFERENCES nutr_def(nutr_no),
    FOREIGN KEY(src_cd)   REFERENCES src_cd(src_cd),
    FOREIGN KEY(deriv_cd) REFERENCES deriv_cd(deriv_cd)
    /*
    Links to the Footnote file by NDB_No and when applicable, Nutr_No.
*/
);
CREATE INDEX nutdata_ndb_nut ON nut_data (ndb_no, nutr_no);

CREATE TABLE nutr_def (
    nutr_no  TEXT NOT NULL PRIMARY KEY,
    units    TEXT NOT NULL,
    tagname  TEXT,
    nutrdesc TEXT NOT NULL,
    num_dec  INTEGER NOT NULL,
    sr_order INTEGER NOT NULL
);

CREATE TABLE src_cd (
    src_cd     TEXT NOT NULL PRIMARY KEY,
    srccd_desc TEXT NOT NULL
);

CREATE TABLE deriv_cd (
    deriv_cd   TEXT NOT NULL PRIMARY KEY,
    deriv_desc TEXT NOT NULL
);

CREATE TABLE weight (
    ndb_no       TEXT NOT NULL,
    seq          TEXT NOT NULL,
    amount       REAL NOT NULL,
    msre_desc    TEXT NOT NULL, 
    gm_wgt       REAL NOT NULL,
    num_data_pts INTEGER,
    std_dev      REAL,
    PRIMARY KEY (ndb_no, seq)
);

/* autogen pk for orlite */
CREATE TABLE footnote (
    id           INTEGER PRIMARY KEY AUTOINCREMENT,
    ndb_no       TEXT NOT NULL,
    footnt_no    TEXT NOT NULL,
    footnt_typ   TEXT NOT NULL,
    nutr_no      TEXT, 
    footnt_txt   TEXT NOT NULL
);

CREATE TABLE datsrcln (
    ndb_no     TEXT NOT NULL,
    nutr_no    TEXT NOT NULL, 
    datasrc_id TEXT NOT NULL,
    PRIMARY KEY (ndb_no, nutr_no, datasrc_id),
    FOREIGN KEY(datasrc_id) REFERENCES data_src(datasrc_id)
);

/* datasrc_id is the primary key according to the docs,
   but there are multiple duplicate keys */
/* title is supposed to be NOT NULL, but there is at least one undef */
CREATE TABLE data_src (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    datasrc_id  TEXT NOT NULL,
    authors     TEXT, 
    title       TEXT,
    year        INTEGER,
    journal     TEXT,
    vol_city    TEXT,
    issue_state TEXT,
    start_page  TEXT,
    end_page    TEXT
);
