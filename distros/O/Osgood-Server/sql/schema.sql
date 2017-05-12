CREATE TABLE `actions` (
  `action_id` bigint(20) unsigned NOT NULL auto_increment,
  `name` varchar(64) NOT NULL,
  PRIMARY KEY  (`action_id`),
  UNIQUE KEY `action_id` (`action_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `objects` (
  `object_id` bigint(20) unsigned NOT NULL auto_increment,
  `name` varchar(64) NOT NULL,
  PRIMARY KEY  (`object_id`),
  UNIQUE KEY `object_id` (`object_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `events` (
  `event_id` bigint(20) unsigned NOT NULL auto_increment,
  `object_id` bigint(20) unsigned NOT NULL,
  `action_id` bigint(20) unsigned NOT NULL,
  `date_occurred` datetime NOT NULL,
  PRIMARY KEY  (`event_id`),
  UNIQUE KEY `event_id` (`event_id`),
  KEY `action_id` (`action_id`),
  KEY `events_object_action_idx` (`object_id`,`action_id`),
  CONSTRAINT `actions_fk_action_id` FOREIGN KEY (`action_id`) REFERENCES `actions` (`action_id`),
  CONSTRAINT `objects_fk_object_id` FOREIGN KEY (`object_id`) REFERENCES `objects` (`object_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `event_parameters` (
  `event_parameter_id` bigint(20) unsigned NOT NULL auto_increment,
  `event_id` bigint(20) unsigned NOT NULL,
  `name` varchar(64) NOT NULL,
  `value` varchar(255) default NULL,
  PRIMARY KEY  (`event_parameter_id`),
  UNIQUE KEY `event_parameter_id` (`event_parameter_id`),
  KEY `event_id` (`event_id`),
  CONSTRAINT `events_fk_event_id` FOREIGN KEY (`event_id`) REFERENCES `events` (`event_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

