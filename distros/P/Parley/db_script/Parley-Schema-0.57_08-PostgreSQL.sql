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
  thread_id smallint DEFAULT 'nextval('thread_thread_id_seq'::regclass)' NOT NULL,
  locked boolean(1) DEFAULT 'false' NOT NULL,
  creator smallint NOT NULL,
  subject text NOT NULL,
  active boolean(1) DEFAULT 'true' NOT NULL,
  forum smallint NOT NULL,
  created timestamp with time zone(6) DEFAULT now(),
  last_post smallint,
  sticky boolean(1) DEFAULT 'false' NOT NULL,
  post_count smallint DEFAULT '0' NOT NULL,
  view_count smallint DEFAULT '0' NOT NULL,
  PRIMARY KEY (thread_id)
);



--
-- Table: forum
--
DROP TABLE forum CASCADE;
CREATE TABLE forum (
  last_post smallint,
  post_count smallint DEFAULT '0' NOT NULL,
  forum_id smallint DEFAULT 'nextval('forum_forum_id_seq'::regclass)' NOT NULL,
  active boolean(1) DEFAULT 'true' NOT NULL,
  name text NOT NULL,
  description text,
  PRIMARY KEY (forum_id),
  Constraint "forum_name_key" UNIQUE (name)
);



--
-- Table: authentication
--
DROP TABLE authentication CASCADE;
CREATE TABLE authentication (
  authentication_id smallint DEFAULT 'nextval('authentication_authentication_id_seq'::regclass)' NOT NULL,
  password text NOT NULL,
  authenticated boolean(1) DEFAULT 'false' NOT NULL,
  username text NOT NULL,
  PRIMARY KEY (authentication_id),
  Constraint "authentication_username_key" UNIQUE (username)
);



--
-- Table: preference
--
DROP TABLE preference CASCADE;
CREATE TABLE preference (
  timezone text DEFAULT ''UTC'::text' NOT NULL,
  preference_id smallint DEFAULT 'nextval('preference_preference_id_seq'::regclass)' NOT NULL,
  time_format smallint NOT NULL,
  show_tz boolean(1) DEFAULT 'true' NOT NULL,
  notify_thread_watch boolean(1) DEFAULT 'false' NOT NULL,
  watch_on_post boolean(1) DEFAULT 'false' NOT NULL,
  PRIMARY KEY (preference_id)
);



--
-- Table: email_queue
--
DROP TABLE email_queue CASCADE;
CREATE TABLE email_queue (
  recipient smallint NOT NULL,
  cc smallint,
  bcc smallint,
  sender text,
  subject text NOT NULL,
  html_content text,
  email_queue_id smallint DEFAULT 'nextval('email_queue_email_queue_id_seq'::regclass)' NOT NULL,
  attempted_delivery boolean(1) DEFAULT 'false' NOT NULL,
  text_content text NOT NULL,
  queued timestamp with time zone(6) DEFAULT now() NOT NULL,
  PRIMARY KEY (email_queue_id)
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
  password_reset_id integer NOT NULL,
  recipient smallint NOT NULL,
  expires timestamp without time zone(6),
  PRIMARY KEY (password_reset_id)
);



--
-- Table: post
--
DROP TABLE post CASCADE;
CREATE TABLE post (
  creator smallint NOT NULL,
  subject text,
  quoted_post smallint,
  message text NOT NULL,
  quoted_text text,
  created timestamp with time zone(6) DEFAULT now(),
  thread smallint NOT NULL,
  reply_to smallint,
  post_id smallint DEFAULT 'nextval('post_post_id_seq'::regclass)' NOT NULL,
  edited timestamp with time zone(6),
  ip_addr inet(8),
  PRIMARY KEY (post_id)
);



--
-- Table: forum_moderator
--
DROP TABLE forum_moderator CASCADE;
CREATE TABLE forum_moderator (
  person smallint NOT NULL,
  forum smallint NOT NULL,
  can_moderate boolean(1) DEFAULT 'false' NOT NULL,
  Constraint "forum_moderator_person_key" UNIQUE (person, forum)
);



--
-- Table: thread_view
--
DROP TABLE thread_view CASCADE;
CREATE TABLE thread_view (
  watched boolean(1) DEFAULT 'false' NOT NULL,
  thread_view_id smallint DEFAULT 'nextval('thread_view_thread_view_id_seq'::regclass)' NOT NULL,
  last_notified timestamp with time zone(6),
  thread smallint NOT NULL,
  timestamp timestamp with time zone(6) DEFAULT now() NOT NULL,
  person smallint NOT NULL,
  PRIMARY KEY (thread_view_id),
  Constraint "thread_view_person_key" UNIQUE (person, thread)
);



--
-- Table: person
--
DROP TABLE person CASCADE;
CREATE TABLE person (
  person_id smallint DEFAULT 'nextval('person_person_id_seq'::regclass)' NOT NULL,
  authentication smallint,
  last_name text NOT NULL,
  email text NOT NULL,
  forum_name text NOT NULL,
  preference smallint,
  last_post smallint,
  post_count smallint DEFAULT '0' NOT NULL,
  first_name text NOT NULL,
  PRIMARY KEY (person_id),
  Constraint "person_forum_name_key" UNIQUE (forum_name),
  Constraint "person_email_key" UNIQUE (email)
);



--
-- Table: registration_authentication
--
DROP TABLE registration_authentication CASCADE;
CREATE TABLE registration_authentication (
  recipient smallint NOT NULL,
  registration_authentication_id text NOT NULL,
  expires date(4),
  PRIMARY KEY (registration_authentication_id)
);



--
-- Table: preference_time_string
--
DROP TABLE preference_time_string CASCADE;
CREATE TABLE preference_time_string (
  preference_time_string_id smallint DEFAULT 'nextval('preference_time_string_preference_time_string_id_seq'::regclass)' NOT NULL,
  time_string text NOT NULL,
  sample text NOT NULL,
  comment text,
  PRIMARY KEY (preference_time_string_id)
);

--
-- Foreign Key Definitions
--

ALTER TABLE thread ADD FOREIGN KEY (last_post)
  REFERENCES post (post_id) ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE thread ADD FOREIGN KEY (forum)
  REFERENCES forum_moderator (forum);

ALTER TABLE thread ADD FOREIGN KEY (creator)
  REFERENCES person (person_id) ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE thread ADD FOREIGN KEY (forum)
  REFERENCES forum (forum_id) ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE forum ADD FOREIGN KEY (last_post)
  REFERENCES post (post_id) ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE preference ADD FOREIGN KEY (time_format)
  REFERENCES preference_time_string (preference_time_string_id);

ALTER TABLE email_queue ADD FOREIGN KEY (recipient)
  REFERENCES person (person_id) ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE terms_agreed ADD FOREIGN KEY (person_id)
  REFERENCES person (person_id);

ALTER TABLE terms_agreed ADD FOREIGN KEY (terms_id)
  REFERENCES terms (id);

ALTER TABLE password_reset ADD FOREIGN KEY (recipient)
  REFERENCES person (person_id);

ALTER TABLE post ADD FOREIGN KEY (creator)
  REFERENCES person (person_id) ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE post ADD FOREIGN KEY (quoted_post)
  REFERENCES post (post_id) ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE post ADD FOREIGN KEY (thread)
  REFERENCES thread (thread_id) ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE post ADD FOREIGN KEY (reply_to)
  REFERENCES post (post_id) ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE forum_moderator ADD FOREIGN KEY (person)
  REFERENCES person (person_id);

ALTER TABLE forum_moderator ADD FOREIGN KEY (forum)
  REFERENCES forum (forum_id);

ALTER TABLE thread_view ADD FOREIGN KEY (thread)
  REFERENCES thread (thread_id) ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE thread_view ADD FOREIGN KEY (person)
  REFERENCES person (person_id) ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE person ADD FOREIGN KEY (last_post)
  REFERENCES post (post_id) ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE person ADD FOREIGN KEY (preference)
  REFERENCES preference (preference_id) ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE person ADD FOREIGN KEY (authentication)
  REFERENCES authentication (authentication_id) ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE registration_authentication ADD FOREIGN KEY (recipient)
  REFERENCES person (person_id) ON DELETE CASCADE ON UPDATE CASCADE;
