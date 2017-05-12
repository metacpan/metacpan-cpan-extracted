-- 
-- Created by SQL::Translator::Producer::SQLite
-- Created on Mon Jan 14 19:14:00 2008
-- 
BEGIN TRANSACTION;


--
-- Table: terms
--
DROP TABLE terms;
CREATE TABLE terms (
  id INTEGER PRIMARY KEY NOT NULL,
  created timestamp with time zone NOT NULL,
  content text NOT NULL,
  change_summary text NOT NULL
);


--
-- Table: thread
--
DROP TABLE thread;
CREATE TABLE thread (
  id INTEGER PRIMARY KEY NOT NULL,
  locked boolean(1) NOT NULL DEFAULT 'false',
  creator_id integer(4) NOT NULL,
  subject text NOT NULL,
  active boolean(1) NOT NULL DEFAULT 'true',
  forum_id integer(4) NOT NULL,
  created timestamp with time zone(8) DEFAULT CURRENT_TIMESTAMP,
  last_post_id integer(4),
  sticky boolean(1) NOT NULL DEFAULT 'false',
  post_count integer(4) NOT NULL DEFAULT '0',
  view_count integer(4) NOT NULL DEFAULT '0'
);


--
-- Table: forum
--
DROP TABLE forum;
CREATE TABLE forum (
  id INTEGER PRIMARY KEY NOT NULL,
  last_post_id integer(4),
  post_count integer(4) NOT NULL DEFAULT '0',
  active boolean(1) NOT NULL DEFAULT 'true',
  name text NOT NULL,
  description text
);

CREATE UNIQUE INDEX forum_name_key_forum on forum (name);

--
-- Table: preference
--
DROP TABLE preference;
CREATE TABLE preference (
  id INTEGER PRIMARY KEY NOT NULL,
  timezone text NOT NULL DEFAULT 'UTC',
  time_format_id integer(4) NOT NULL,
  show_tz boolean(1) NOT NULL DEFAULT 'true',
  notify_thread_watch boolean(1) NOT NULL DEFAULT 'false',
  watch_on_post boolean(1) NOT NULL DEFAULT 'false'
);


--
-- Table: authentication
--
DROP TABLE authentication;
CREATE TABLE authentication (
  id INTEGER PRIMARY KEY NOT NULL,
  password text NOT NULL,
  authenticated boolean(1) NOT NULL DEFAULT 'false',
  username text NOT NULL
);

CREATE UNIQUE INDEX authentication_username_key_au on authentication (username);

--
-- Table: email_queue
--
DROP TABLE email_queue;
CREATE TABLE email_queue (
  id INTEGER PRIMARY KEY NOT NULL,
  recipient_id integer(4) NOT NULL,
  cc_id integer(4),
  bcc_id integer(4),
  sender text,
  subject text NOT NULL,
  html_content text,
  attempted_delivery boolean(1) NOT NULL DEFAULT 'false',
  text_content text NOT NULL,
  queued timestamp with time zone(8) NOT NULL DEFAULT CURRENT_TIMESTAMP
);


--
-- Table: terms_agreed
--
DROP TABLE terms_agreed;
CREATE TABLE terms_agreed (
  id INTEGER PRIMARY KEY NOT NULL,
  person_id integer NOT NULL,
  terms_id integer NOT NULL,
  accepted_on timestamp with time zone NOT NULL
);


--
-- Table: password_reset
--
DROP TABLE password_reset;
CREATE TABLE password_reset (
  id INTEGER PRIMARY KEY NOT NULL,
  recipient_id integer(4) NOT NULL,
  expires timestamp without time zone(8)
);


--
-- Table: post
--
DROP TABLE post;
CREATE TABLE post (
  id INTEGER PRIMARY KEY NOT NULL,
  creator_id integer(4) NOT NULL,
  subject text,
  quoted_post_id integer(4),
  message text NOT NULL,
  quoted_text text,
  created timestamp with time zone(8) DEFAULT CURRENT_TIMESTAMP,
  thread_id integer(4) NOT NULL,
  reply_to_id integer(4),
  edited timestamp with time zone(8),
  ip_addr inet(8)
);


--
-- Table: forum_moderator
--
DROP TABLE forum_moderator;
CREATE TABLE forum_moderator (
  person_id integer(4) NOT NULL,
  forum_id integer(4) NOT NULL,
  can_moderate boolean(1) NOT NULL DEFAULT 'false'
);

CREATE UNIQUE INDEX forum_moderator_person_key_for on forum_moderator (person_id, forum_id);

--
-- Table: thread_view
--
DROP TABLE thread_view;
CREATE TABLE thread_view (
  id INTEGER PRIMARY KEY NOT NULL,
  watched boolean(1) NOT NULL DEFAULT 'false',
  last_notified timestamp with time zone(8),
  thread_id integer(4) NOT NULL,
  timestamp timestamp with time zone(8) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  person_id integer(4) NOT NULL
);

CREATE UNIQUE INDEX thread_view_person_key_thread_ on thread_view (person_id, thread_id);

--
-- Table: person
--
DROP TABLE person;
CREATE TABLE person (
  id INTEGER PRIMARY KEY NOT NULL,
  authentication_id integer(4),
  last_name text NOT NULL,
  email text NOT NULL,
  forum_name text NOT NULL,
  preference_id integer(4),
  last_post_id integer(4),
  post_count integer(4) NOT NULL DEFAULT '0',
  first_name text NOT NULL
);

CREATE UNIQUE INDEX person_forum_name_key_person on person (forum_name);
CREATE UNIQUE INDEX person_email_key_person on person (email);

--
-- Table: registration_authentication
--
DROP TABLE registration_authentication;
CREATE TABLE registration_authentication (
  id text NOT NULL,
  recipient_id integer(4) NOT NULL,
  expires date(4),
  PRIMARY KEY (id)
);


--
-- Table: preference_time_string
--
DROP TABLE preference_time_string;
CREATE TABLE preference_time_string (
  id INTEGER PRIMARY KEY NOT NULL,
  time_string text NOT NULL,
  sample text NOT NULL,
  comment text
);


COMMIT;
