
-- This is a MyLibrary database schema for Postgresql provided by Emil-Nicolaie Perhinschi
-- September 9, 2007


--
--  Table structure for table 'components4interfaces'
-- 

DROP TABLE IF EXISTS components4interfaces;
CREATE TABLE components4interfaces (
  interface_component_id integer NOT NULL default '0',
  interface_id integer NOT NULL default '0',
  PRIMARY KEY (interface_component_id,interface_id)
) ;

-- 
--  Table structure for table 'facets'
-- 

DROP TABLE IF EXISTS facets;
CREATE TABLE facets (
  facet_id integer NOT NULL default '0',
  facet_name varchar(255) NOT NULL default '',
  facet_note text,
  PRIMARY KEY  (facet_id),
  unique(facet_name)
);
create index facet_name on facets (facet_name);
create index facet_name_2 on facets (facet_name);

-- 
--  Table structure for table 'help_simple'
-- 

DROP TABLE IF EXISTS help_simple;
CREATE TABLE help_simple (
  help_id integer NOT NULL default '0',
  help_title varchar(255) default NULL,
  help_text text,
  PRIMARY KEY  (help_id)
) ;

-- 
--  Table structure for table 'interface'
-- 

DROP TABLE IF EXISTS interface;
CREATE TABLE interface (
  interface_id bigint NOT NULL default '0',
  name varchar(255) NOT NULL default '',
  html text NOT NULL,
  options text,
  PRIMARY KEY  (interface_id),
  unique(name)
) ;
create index name on interfaces (name);

-- 
--  Table structure for table 'interface_component'
-- 

DROP TABLE IF EXISTS interface_component;
CREATE TABLE interface_component (
  interface_component_id bigint NOT NULL default '0',
  name varchar(255) NOT NULL default '',
  html text NOT NULL,
  options text,
  PRIMARY KEY  (interface_component_id),
  unique(name)
);
create index name on interface_component (name);

-- 
--  Table structure for table 'librarians'
-- 

DROP TABLE IF EXISTS librarians;
CREATE TABLE librarians (
  librarian_id integer NOT NULL default '0',
  name varchar(255) default NULL,
  telephone varchar(255) NOT NULL default '',
  email varchar(255) default NULL,
  url varchar(255) default NULL,
  PRIMARY KEY  (librarian_id)
) ;

-- 
--  Table structure for table 'messages'
-- 

DROP TABLE IF EXISTS messages;
CREATE TABLE messages (
  message_id integer NOT NULL default '0',
  message_date date NOT NULL default '0001-01-01',
  message text NOT NULL,
  message_global smallint NOT NULL default '2',
  PRIMARY KEY  (message_id)
);

-- 
--  Table structure for table 'new_item_profiles'
-- 

DROP TABLE IF EXISTS new_item_profiles;
CREATE TABLE new_item_profiles (
  profile_id integer NOT NULL default '0',
  profile text NOT NULL,
  patron_id bigint NOT NULL default '0',
  PRIMARY KEY  (profile_id)
) ;

-- 
--  Table structure for table 'patron_resource'
-- 

DROP TABLE IF EXISTS patron_resource;
CREATE TABLE patron_resource (
  resource_id integer NOT NULL default '0',
  patron_id integer NOT NULL default '0',
  usage_count integer NOT NULL default '0',
  patron_owned smallint NOT NULL default '0',
  PRIMARY KEY  (resource_id,patron_id)
) ;

-- 
--  Table structure for table 'patron_term'
-- 

DROP TABLE IF EXISTS patron_term;
CREATE TABLE patron_term (
  patron_id integer NOT NULL default '0',
  term_id integer NOT NULL default '0',
  PRIMARY KEY  (patron_id,term_id)
) ;

-- 
--  Table structure for table 'patrons'
-- 

DROP TABLE IF EXISTS patrons;
CREATE TABLE patrons (
  patron_id integer NOT NULL default '0',
  patron_firstname varchar(255) default NULL,
  patron_surname varchar(255) default NULL,
  patron_image varchar(255) default NULL,
  patron_url varchar(255) default NULL,
  patron_username varchar(255) default NULL,
  patron_organization varchar(255) default NULL,
  patron_address_1 varchar(255) default NULL,
  patron_address_2 varchar(255) default NULL,
  patron_address_3 varchar(255) default NULL,
  patron_address_4 varchar(255) default NULL,
  patron_address_5 varchar(255) default NULL,
  patron_can_contact smallint default NULL,
  patron_password varchar(255) default NULL,
  patron_total_visits integer default NULL,
  patron_last_visit date default NULL,
  patron_remember_me smallint default NULL,
  patron_email varchar(255) default NULL,
  patron_stylesheet_id integer NOT NULL default '0',
  PRIMARY KEY  (patron_id)
) ;

-- 
--  Table structure for table 'personallinks'
-- 

DROP TABLE IF EXISTS personallinks;
CREATE TABLE personallinks (
  link_id integer NOT NULL default '0',
  patron_id integer default NULL,
  link_name varchar(255) default NULL,
  link_url varchar(255) default NULL,
  PRIMARY KEY  (link_id)
) ;

-- 
--  Table structure for table 'preferences'
-- 

DROP TABLE IF EXISTS preferences;
CREATE TABLE preferences (
  PREFERNECE_ID integer NOT NULL default '0',
  SHOW_QUICK_SEARCHES smallint NOT NULL default '0',
  MESSSAGE_FROM_LIBRARIAN varchar(255) NOT NULL default '',
  YOUR_LIBRARIANS varchar(255) NOT NULL default '',
  CURRENT_AWARENESS varchar(255) NOT NULL default '',
  PERSONAL_LINKS varchar(255) NOT NULL default '',
  FOOTER text NOT NULL,
  header text NOT NULL,
  SHOW_LIBREF smallint NOT NULL default '0',
  GENERIC_BLURB text NOT NULL,
  SHOW_CAM smallint NOT NULL default '0',
  MARION varchar(255) NOT NULL default '',
  DISCLAIMER text NOT NULL,
  FROM_ADDRESS varchar(255) NOT NULL default '',
  EXPIRES varchar(255) NOT NULL default '',
  PAGE_TITLE varchar(255) NOT NULL default '',
  SAVE_STATISTICS smallint NOT NULL default '0',
  MANAGE_DISCIPLINE smallint NOT NULL default '0',
  STATIC_PAGES_SHOW smallint NOT NULL default '0',
  LIBRARIAN_BLURB text NOT NULL,
  MANAGER_BLURB text NOT NULL,
  facet_id integer NOT NULL default '0',
  TEMPLATE_ID integer NOT NULL default '0',
  TEMPLATE_FREE_ID integer NOT NULL default '0',
  stylesheet_id integer NOT NULL default '0',
  PRIMARY KEY  (PREFERNECE_ID)
) ;

-- 
--  Table structure for table 'resource_location'
-- 

DROP TABLE IF EXISTS resource_location;
CREATE TABLE resource_location (
  resource_location_id integer NOT NULL default '0',
  resource_location text NOT NULL,
  resource_location_note varchar(255) default NULL,
  resource_location_type integer NOT NULL default '0',
  resource_id integer NOT NULL default '0',
  PRIMARY KEY  (resource_location_id)
);

-- 
--  Table structure for table 'resource_location_type'
-- 

DROP TABLE IF EXISTS resource_location_type;
CREATE TABLE resource_location_type (
  type_id integer NOT NULL default '0',
  type_name varchar(255) NOT NULL default '',
  type_description text,
  PRIMARY KEY  (type_id),
  unique(type_name)
);
create index type_name on resource_location_type (type_name);

-- 
--  Table structure for table 'resources'
-- 

DROP TABLE IF EXISTS resources;
CREATE TABLE resources (
  resource_id integer NOT NULL default '0',
  resource_name varchar(255) NOT NULL default '',
  resource_note text,
  resource_fkey varchar(255) default '',
  resource_date date default '0001-01-01',
  resource_lcd smallint default '0',
  qsearch_prefix varchar(255) default '',
  qsearch_suffix varchar(255) default '',
  resource_proxied smallint NOT NULL default '0',
  resource_creator varchar(255) default NULL,
  resource_publisher varchar(255) default NULL,
  resource_contributor varchar(255) default NULL,
  resource_coverage varchar(255) default NULL,
  resource_rights varchar(255) default NULL,
  resource_language varchar(255) default NULL,
  resource_source varchar(255) default NULL,
  resource_relation varchar(255) default NULL,
  resource_access_note varchar(255) default NULL,
  resource_coverage_info varchar(255) default NULL,
  resource_full_text smallint NOT NULL default '0',
  resource_reference_linking smallint NOT NULL default '0',
  resource_format varchar(255) default NULL,
  resource_type varchar(255) default NULL,
  resource_subject varchar(255) default NULL,
  resource_create_date date default NULL,
  PRIMARY KEY  (resource_id)
);
create index resource_name on resources (resource_name);


-- 
--  Table structure for table 'reviews'
-- 

DROP TABLE IF EXISTS reviews;
CREATE TABLE reviews (
  review_id integer NOT NULL default '0',
  review text NOT NULL,
  reviewer_name varchar(255) NOT NULL default '',
  reviewer_email varchar(255) NOT NULL default '',
  review_date date NOT NULL default '0001-01-01',
  review_rating varchar(255) NOT NULL default '',
  term_id integer NOT NULL default '0',
  resource_id integer NOT NULL default '0',
  PRIMARY KEY  (review_id)
);

-- 
--  Table structure for table 'sequence'
-- 

DROP TABLE IF EXISTS sequence;
CREATE TABLE sequence (
  id integer NOT NULL default '0'
);
INSERT INTO sequence (id) VALUES ('1');

-- 
--  Table structure for table 'sessions'
-- 

DROP TABLE IF EXISTS sessions;
CREATE TABLE sessions (
  id varchar(32) NOT NULL default '',
  a_session text NOT NULL,
  UNIQUE(id)
);
create index id on sessions(id);
-- 
--  Table structure for table 'statistics'
-- 

DROP TABLE IF EXISTS statistics;
CREATE TABLE statistics (
  statistic_id integer NOT NULL default '0',
  resource_id integer NOT NULL default '0',
  statistic_date date NOT NULL default '0001-01-01',
  statistic_query varchar(255) NOT NULL default '',
  PRIMARY KEY  (statistic_id)
);

-- 
--  Table structure for table 'stylesheets'
-- 

DROP TABLE IF EXISTS stylesheets;
CREATE TABLE stylesheets (
  stylesheet_id integer NOT NULL default '0',
  stylesheet_name varchar(255) NOT NULL default '',
  stylesheet_description text NOT NULL,
  stylesheet text NOT NULL,
  PRIMARY KEY  (stylesheet_id),
  UNIQUE(stylesheet_name)
);
create index stylesheet_name on stylesheets (stylesheet_name);

-- 
--  Table structure for table 'suggestedResources'
-- 

DROP TABLE IF EXISTS suggestedResources;
CREATE TABLE suggestedResources (
  term_id integer NOT NULL default '0',
  resource_id integer NOT NULL default '0',
  PRIMARY KEY  (resource_id,term_id)
) ;

-- 
--  Table structure for table 'terms'
-- 

DROP TABLE IF EXISTS terms;
CREATE TABLE terms (
  term_id integer NOT NULL default '0',
  term_name varchar(255) NOT NULL default '',
  term_note text,
  facet_id integer NOT NULL default '0',
  PRIMARY KEY  (term_id),
  UNIQUE(term_name)
);
create index term_name on terms (term_name);
create index facet_id on terms (facet_id);
-- 
--  Table structure for table 'terms_librarians'
-- 

DROP TABLE IF EXISTS terms_librarians;
CREATE TABLE terms_librarians (
  term_id integer NOT NULL default '0',
  librarian_id integer NOT NULL default '0',
  PRIMARY KEY  (term_id,librarian_id)
);

-- 
--  Table structure for table 'terms_messages'
-- 

DROP TABLE IF EXISTS terms_messages;
CREATE TABLE terms_messages (
  message_id integer NOT NULL default '0',
  term_id integer NOT NULL default '0',
  PRIMARY KEY  (message_id,term_id)
);

-- 
--  Table structure for table 'terms_resources'
-- 

DROP TABLE IF EXISTS terms_resources;
CREATE TABLE terms_resources (
  resource_id integer NOT NULL default '0',
  term_id integer NOT NULL default '0',
  PRIMARY KEY  (resource_id,term_id)
);
create index term_id on terms_resources (term_id);


-- commented out by ELM on 09/06/2007 because the user mylib might not exist

-- grant all privileges on components4interfaces, facets,  help_simple,interface, interface_component, librarians, messages,
-- 			new_item_profiles, patron_resource, patron_term, patrons, personallinks, preferences, 
-- 			resource_location, resource_location_type, resources, reviews, sequence,
-- 			sessions, statistics, stylesheets, suggestedresources, 
-- 			terms, terms_librarians, terms_messages, terms_resources
-- 	to mylib;
