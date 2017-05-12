--
-- Table: terms
--
DROP TABLE terms CASCADE;
CREATE TABLE terms (
  id integer NOT NULL,
  created timestamp with time zone NOT NULL,
  content text NOT NULL,
  change_summary text NOT NULL,
  PRIMARY KEY (id)
);



--
-- Table: thread
--
DROP TABLE thread CASCADE;
CREATE TABLE thread (
  id smallint DEFAULT 'nextval('thread_thread_id_seq'::regclass)' NOT NULL,
  locked boolean(1) DEFAULT 'false' NOT NULL,
  creator_id smallint NOT NULL,
  subject text NOT NULL,
  active boolean(1) DEFAULT 'true' NOT NULL,
  forum_id smallint NOT NULL,
  created timestamp with time zone(6) DEFAULT now(),
  last_post_id smallint,
  sticky boolean(1) DEFAULT 'false' NOT NULL,
  post_count smallint DEFAULT '0' NOT NULL,
  view_count smallint DEFAULT '0' NOT NULL,
  PRIMARY KEY (id)
);



--
-- Table: forum
--
DROP TABLE forum CASCADE;
CREATE TABLE forum (
  id smallint DEFAULT 'nextval('forum_forum_id_seq'::regclass)' NOT NULL,
  last_post_id smallint,
  post_count smallint DEFAULT '0' NOT NULL,
  active boolean(1) DEFAULT 'true' NOT NULL,
  name text NOT NULL,
  description text,
  PRIMARY KEY (id),
  Constraint "forum_name_key" UNIQUE (name)
);



--
-- Table: authentication
--
DROP TABLE authentication CASCADE;
CREATE TABLE authentication (
  id smallint DEFAULT 'nextval('authentication_authentication_id_seq'::regclass)' NOT NULL,
  password text NOT NULL,
  authenticated boolean(1) DEFAULT 'false' NOT NULL,
  username text NOT NULL,
  PRIMARY KEY (id),
  Constraint "authentication_username_key" UNIQUE (username)
);



--
-- Table: preference
--
DROP TABLE preference CASCADE;
CREATE TABLE preference (
  id smallint DEFAULT 'nextval('preference_preference_id_seq'::regclass)' NOT NULL,
  timezone text DEFAULT ''UTC'::text' NOT NULL,
  time_format_id smallint NOT NULL,
  show_tz boolean(1) DEFAULT 'true' NOT NULL,
  notify_thread_watch boolean(1) DEFAULT 'false' NOT NULL,
  watch_on_post boolean(1) DEFAULT 'false' NOT NULL,
  PRIMARY KEY (id)
);



--
-- Table: email_queue
--
DROP TABLE email_queue CASCADE;
CREATE TABLE email_queue (
  id smallint DEFAULT 'nextval('email_queue_email_queue_id_seq'::regclass)' NOT NULL,
  recipient_id smallint NOT NULL,
  cc_id smallint,
  bcc_id smallint,
  sender text,
  subject text NOT NULL,
  html_content text,
  attempted_delivery boolean(1) DEFAULT 'false' NOT NULL,
  text_content text NOT NULL,
  queued timestamp with time zone(6) DEFAULT now() NOT NULL,
  PRIMARY KEY (id)
);



--
-- Table: terms_agreed
--
DROP TABLE terms_agreed CASCADE;
CREATE TABLE terms_agreed (
  id integer NOT NULL,
  person_id integer NOT NULL,
  terms_id integer NOT NULL,
  accepted_on timestamp with time zone NOT NULL,
  PRIMARY KEY (id)
);



--
-- Table: password_reset
--
DROP TABLE password_reset CASCADE;
CREATE TABLE password_reset (
  id integer NOT NULL,
  recipient_id smallint NOT NULL,
  expires timestamp without time zone(6),
  PRIMARY KEY (id)
);



--
-- Table: post
--
DROP TABLE post CASCADE;
CREATE TABLE post (
  id smallint DEFAULT 'nextval('post_post_id_seq'::regclass)' NOT NULL,
  creator_id smallint NOT NULL,
  subject text,
  quoted_post_id smallint,
  message text NOT NULL,
  quoted_text text,
  created timestamp with time zone(6) DEFAULT now(),
  thread_id smallint NOT NULL,
  reply_to_id smallint,
  edited timestamp with time zone(6),
  ip_addr inet(8),
  PRIMARY KEY (id)
);



--
-- Table: forum_moderator
--
DROP TABLE forum_moderator CASCADE;
CREATE TABLE forum_moderator (
  person_id smallint NOT NULL,
  forum_id smallint NOT NULL,
  can_moderate boolean(1) DEFAULT 'false' NOT NULL,
  Constraint "forum_moderator_person_key" UNIQUE (person_id, forum_id)
);



--
-- Table: thread_view
--
DROP TABLE thread_view CASCADE;
CREATE TABLE thread_view (
  id smallint DEFAULT 'nextval('thread_view_thread_view_id_seq'::regclass)' NOT NULL,
  watched boolean(1) DEFAULT 'false' NOT NULL,
  last_notified timestamp with time zone(6),
  thread_id smallint NOT NULL,
  timestamp timestamp with time zone(6) DEFAULT now() NOT NULL,
  person_id smallint NOT NULL,
  PRIMARY KEY (id),
  Constraint "thread_view_person_key" UNIQUE (person_id, thread_id)
);



--
-- Table: person
--
DROP TABLE person CASCADE;
CREATE TABLE person (
  id smallint DEFAULT 'nextval('person_person_id_seq'::regclass)' NOT NULL,
  authentication_id smallint,
  last_name text NOT NULL,
  email text NOT NULL,
  forum_name text NOT NULL,
  preference_id smallint,
  last_post_id smallint,
  post_count smallint DEFAULT '0' NOT NULL,
  first_name text NOT NULL,
  PRIMARY KEY (id),
  Constraint "person_forum_name_key" UNIQUE (forum_name),
  Constraint "person_email_key" UNIQUE (email)
);



--
-- Table: registration_authentication
--
DROP TABLE registration_authentication CASCADE;
CREATE TABLE registration_authentication (
  id text NOT NULL,
  recipient_id smallint NOT NULL,
  expires date(4),
  PRIMARY KEY (id)
);



--
-- Table: preference_time_string
--
DROP TABLE preference_time_string CASCADE;
CREATE TABLE preference_time_string (
  id smallint DEFAULT 'nextval('preference_time_string_preference_time_string_id_seq'::regclass)' NOT NULL,
  time_string text NOT NULL,
  sample text NOT NULL,
  comment text,
  PRIMARY KEY (id)
);

--
-- Foreign Key Definitions
--

ALTER TABLE thread ADD FOREIGN KEY (last_post_id)
  REFERENCES post (id) ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE thread ADD FOREIGN KEY (forum_id)
  REFERENCES forum_moderator (forum);

ALTER TABLE thread ADD FOREIGN KEY (creator_id)
  REFERENCES person (id) ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE thread ADD FOREIGN KEY (forum_id)
  REFERENCES forum (id);

ALTER TABLE forum ADD FOREIGN KEY (last_post_id)
  REFERENCES post (id) ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE preference ADD FOREIGN KEY (preference_id)
  REFERENCES person (id);

ALTER TABLE preference ADD FOREIGN KEY (time_format_id)
  REFERENCES preference_time_string (id);

ALTER TABLE email_queue ADD FOREIGN KEY (bcc_id)
  REFERENCES person (id);

ALTER TABLE email_queue ADD FOREIGN KEY (cc_id)
  REFERENCES person (id);

ALTER TABLE email_queue ADD FOREIGN KEY (recipient_id)
  REFERENCES person (id) ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE terms_agreed ADD FOREIGN KEY (person_id)
  REFERENCES person (id);

ALTER TABLE terms_agreed ADD FOREIGN KEY (terms_id)
  REFERENCES terms (id);

ALTER TABLE password_reset ADD FOREIGN KEY (recipient_id)
  REFERENCES person (id);

ALTER TABLE post ADD FOREIGN KEY (creator_id)
  REFERENCES person (id) ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE post ADD FOREIGN KEY (quoted_post_id)
  REFERENCES post (id);

ALTER TABLE post ADD FOREIGN KEY (thread_id)
  REFERENCES thread (id) ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE post ADD FOREIGN KEY (reply_to_id)
  REFERENCES post (id) ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE forum_moderator ADD FOREIGN KEY (person_id)
  REFERENCES person (id);

ALTER TABLE forum_moderator ADD FOREIGN KEY (forum_id)
  REFERENCES forum (id);

ALTER TABLE thread_view ADD FOREIGN KEY (thread_id)
  REFERENCES thread (id) ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE thread_view ADD FOREIGN KEY (person_id)
  REFERENCES person (id) ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE person ADD FOREIGN KEY (last_post_id)
  REFERENCES post (id);

ALTER TABLE person ADD FOREIGN KEY (preference_id)
  REFERENCES preference (id);

ALTER TABLE person ADD FOREIGN KEY (authentication_id)
  REFERENCES authentication (id) ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE registration_authentication ADD FOREIGN KEY (recipient_id)
  REFERENCES person (id);
