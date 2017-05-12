-- 
-- Created by SQL::Translator::Producer::MySQL
-- Created on Mon Feb 11 08:43:35 2008
-- 
SET foreign_key_checks=0;

DROP TABLE IF EXISTS authentication;
--
-- Table: authentication
--
CREATE TABLE authentication (
  id integer(4) NOT NULL,
  password text NOT NULL,
  authenticated enum('0','1') NOT NULL DEFAULT 'false',
  username text NOT NULL,
  INDEX (id),
  INDEX (username),
  PRIMARY KEY (id),
  UNIQUE authentication_username_key (username)
) Type=InnoDB;

DROP TABLE IF EXISTS email_queue;
--
-- Table: email_queue
--
CREATE TABLE email_queue (
  id integer(4) NOT NULL,
  recipient_id integer(4) NOT NULL,
  cc_id integer(4),
  bcc_id integer(4),
  sender text,
  subject text NOT NULL,
  html_content text,
  attempted_delivery enum('0','1') NOT NULL DEFAULT 'false',
  text_content text NOT NULL,
  queued timestamp with time zone(8) NOT NULL DEFAULT 'now()',
  INDEX (id),
  INDEX (bcc_id),
  INDEX (cc_id),
  INDEX (recipient_id),
  PRIMARY KEY (id),
  CONSTRAINT email_queue_fk_bcc_id FOREIGN KEY (bcc_id) REFERENCES person (id),
  CONSTRAINT email_queue_fk_cc_id FOREIGN KEY (cc_id) REFERENCES person (id),
  CONSTRAINT email_queue_fk_recipient_id FOREIGN KEY (recipient_id) REFERENCES person (id) ON DELETE CASCADE ON UPDATE CASCADE
) Type=InnoDB;

DROP TABLE IF EXISTS forum;
--
-- Table: forum
--
CREATE TABLE forum (
  id integer(4) NOT NULL,
  last_post_id integer(4),
  post_count integer(4) NOT NULL DEFAULT '0',
  active enum('0','1') NOT NULL DEFAULT 'true',
  name text NOT NULL,
  description text,
  INDEX (id),
  INDEX (name),
  INDEX (last_post_id),
  PRIMARY KEY (id),
  UNIQUE forum_name_key (name),
  CONSTRAINT forum_fk_last_post_id FOREIGN KEY (last_post_id) REFERENCES post (id) ON DELETE CASCADE ON UPDATE CASCADE
) Type=InnoDB;

DROP TABLE IF EXISTS forum_moderator;
--
-- Table: forum_moderator
--
CREATE TABLE forum_moderator (
  person_id integer(4) NOT NULL,
  forum_id integer(4) NOT NULL,
  can_moderate enum('0','1') NOT NULL DEFAULT 'false',
  INDEX (person_id),
  INDEX (forum_id),
  UNIQUE forum_moderator_person_key (person_id, forum_id),
  CONSTRAINT forum_moderator_fk_forum_id FOREIGN KEY (forum_id) REFERENCES forum (id),
  CONSTRAINT forum_moderator_fk_person_id FOREIGN KEY (person_id) REFERENCES person (id)
) Type=InnoDB;

DROP TABLE IF EXISTS password_reset;
--
-- Table: password_reset
--
CREATE TABLE password_reset (
  id integer NOT NULL,
  recipient_id integer(4) NOT NULL,
  expires timestamp without time zone(8),
  INDEX (id),
  INDEX (recipient_id),
  PRIMARY KEY (id),
  CONSTRAINT password_reset_fk_recipient_id FOREIGN KEY (recipient_id) REFERENCES person (id)
) Type=InnoDB;

DROP TABLE IF EXISTS person;
--
-- Table: person
--
CREATE TABLE person (
  id integer(4) NOT NULL,
  authentication_id integer(4),
  last_name text NOT NULL,
  email text NOT NULL,
  forum_name text NOT NULL,
  preference_id integer(4),
  last_post_id integer(4),
  post_count integer(4) NOT NULL DEFAULT '0',
  first_name text NOT NULL,
  INDEX (id),
  INDEX (forum_name),
  INDEX (email),
  INDEX (authentication_id),
  INDEX (last_post_id),
  INDEX (preference_id),
  PRIMARY KEY (id),
  UNIQUE person_forum_name_key (forum_name),
  UNIQUE person_email_key (email),
  CONSTRAINT person_fk_authentication_id FOREIGN KEY (authentication_id) REFERENCES authentication (id) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT person_fk_last_post_id FOREIGN KEY (last_post_id) REFERENCES post (id),
  CONSTRAINT person_fk_preference_id FOREIGN KEY (preference_id) REFERENCES preference (id)
) Type=InnoDB;

DROP TABLE IF EXISTS post;
--
-- Table: post
--
CREATE TABLE post (
  id integer(4) NOT NULL,
  creator_id integer(4) NOT NULL,
  subject text,
  quoted_post_id integer(4),
  message text NOT NULL,
  quoted_text text,
  created timestamp with time zone(8) DEFAULT 'now()',
  thread_id integer(4) NOT NULL,
  reply_to_id integer(4),
  edited timestamp with time zone(8),
  ip_addr inet(8),
  INDEX (id),
  INDEX (creator_id),
  INDEX (quoted_post_id),
  INDEX (reply_to_id),
  INDEX (thread_id),
  PRIMARY KEY (id),
  CONSTRAINT post_fk_creator_id FOREIGN KEY (creator_id) REFERENCES person (id) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT post_fk_quoted_post_id FOREIGN KEY (quoted_post_id) REFERENCES post (id),
  CONSTRAINT post_fk_reply_to_id FOREIGN KEY (reply_to_id) REFERENCES post (id) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT post_fk_thread_id FOREIGN KEY (thread_id) REFERENCES thread (id) ON DELETE CASCADE ON UPDATE CASCADE
) Type=InnoDB;

DROP TABLE IF EXISTS preference;
--
-- Table: preference
--
CREATE TABLE preference (
  id integer(4) NOT NULL,
  timezone text NOT NULL DEFAULT 'UTC',
  time_format_id integer(4) NOT NULL,
  show_tz enum('0','1') NOT NULL DEFAULT 'true',
  notify_thread_watch enum('0','1') NOT NULL DEFAULT 'false',
  watch_on_post enum('0','1') NOT NULL DEFAULT 'false',
  INDEX (id),
  INDEX (preference_id),
  INDEX (time_format_id),
  PRIMARY KEY (id),
  CONSTRAINT preference_fk_preference_id FOREIGN KEY (preference_id) REFERENCES person (id),
  CONSTRAINT preference_fk_time_format_id FOREIGN KEY (time_format_id) REFERENCES preference_time_string (id)
) Type=InnoDB;

DROP TABLE IF EXISTS preference_time_string;
--
-- Table: preference_time_string
--
CREATE TABLE preference_time_string (
  id integer(4) NOT NULL,
  time_string text NOT NULL,
  sample text NOT NULL,
  comment text,
  INDEX (id),
  PRIMARY KEY (id)
) Type=InnoDB;

DROP TABLE IF EXISTS registration_authentication;
--
-- Table: registration_authentication
--
CREATE TABLE registration_authentication (
  id text NOT NULL,
  recipient_id integer(4) NOT NULL,
  expires date(4),
  INDEX (id),
  INDEX (recipient_id),
  PRIMARY KEY (id),
  CONSTRAINT registration_authentication_fk_recipient_id FOREIGN KEY (recipient_id) REFERENCES person (id)
) Type=InnoDB;

DROP TABLE IF EXISTS terms;
--
-- Table: terms
--
CREATE TABLE terms (
  id integer NOT NULL,
  created timestamp with time zone NOT NULL,
  content text NOT NULL,
  change_summary text NOT NULL,
  INDEX (id),
  PRIMARY KEY (id)
) Type=InnoDB;

DROP TABLE IF EXISTS terms_agreed;
--
-- Table: terms_agreed
--
CREATE TABLE terms_agreed (
  id integer NOT NULL,
  person_id integer NOT NULL,
  terms_id integer NOT NULL,
  accepted_on timestamp with time zone NOT NULL,
  INDEX (id),
  INDEX (person_id),
  INDEX (terms_id),
  PRIMARY KEY (id),
  CONSTRAINT terms_agreed_fk_person_id FOREIGN KEY (person_id) REFERENCES person (id),
  CONSTRAINT terms_agreed_fk_terms_id FOREIGN KEY (terms_id) REFERENCES terms (id)
) Type=InnoDB;

DROP TABLE IF EXISTS thread;
--
-- Table: thread
--
CREATE TABLE thread (
  id integer(4) NOT NULL,
  locked enum('0','1') NOT NULL DEFAULT 'false',
  creator_id integer(4) NOT NULL,
  subject text NOT NULL,
  active enum('0','1') NOT NULL DEFAULT 'true',
  forum_id integer(4) NOT NULL,
  created timestamp with time zone(8) DEFAULT 'now()',
  last_post_id integer(4),
  sticky enum('0','1') NOT NULL DEFAULT 'false',
  post_count integer(4) NOT NULL DEFAULT '0',
  view_count integer(4) NOT NULL DEFAULT '0',
  INDEX (id),
  INDEX (creator_id),
  INDEX (forum_id),
  INDEX (last_post_id),
  PRIMARY KEY (id),
  CONSTRAINT thread_fk_creator_id FOREIGN KEY (creator_id) REFERENCES person (id) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT thread_fk_forum_id FOREIGN KEY (forum_id) REFERENCES forum (id),
  CONSTRAINT thread_fk_forum_id_1 FOREIGN KEY (forum_id) REFERENCES forum_moderator (forum),
  CONSTRAINT thread_fk_last_post_id FOREIGN KEY (last_post_id) REFERENCES post (id) ON DELETE CASCADE ON UPDATE CASCADE
) Type=InnoDB;

DROP TABLE IF EXISTS thread_view;
--
-- Table: thread_view
--
CREATE TABLE thread_view (
  id integer(4) NOT NULL,
  watched enum('0','1') NOT NULL DEFAULT 'false',
  last_notified timestamp with time zone(8),
  thread_id integer(4) NOT NULL,
  timestamp timestamp with time zone(8) NOT NULL DEFAULT 'now()',
  person_id integer(4) NOT NULL,
  INDEX (id),
  INDEX (person_id),
  INDEX (thread_id),
  PRIMARY KEY (id),
  UNIQUE thread_view_person_key (person_id, thread_id),
  CONSTRAINT thread_view_fk_person_id FOREIGN KEY (person_id) REFERENCES person (id) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT thread_view_fk_thread_id FOREIGN KEY (thread_id) REFERENCES thread (id) ON DELETE CASCADE ON UPDATE CASCADE
) Type=InnoDB;

SET foreign_key_checks=1;

