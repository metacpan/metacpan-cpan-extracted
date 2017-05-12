-- N.B some of these tables assume you have a user table with
-- an id column for linking access tokens, etc, to a user
-- and the use of varchar( 255 ) is unlikey to be big enough
-- if you use the jwt_secret option of the plugin to make
-- tokens JWTs (at which point a TEXT field would be required,
-- and then that has an impact on how you defined the indexes
-- and primary keys...)

create table if not exists oauth2_client (
	id            varchar( 255 ) NOT NULL PRIMARY KEY,
	secret        varchar( 255 ) NOT NULL,
	active        boolean        NOT NULL DEFAULT true,
	last_modified timestamp      NOT NULL DEFAULT CURRENT_TIMESTAMP
		ON UPDATE CURRENT_TIMESTAMP
);

create table if not exists oauth2_scope (
	id            bigint         NOT NULL PRIMARY KEY,
	description   varchar( 255 ) NOT NULL,

	UNIQUE KEY( description )
);

create table if not exists oauth2_client_scope (
	client_id     varchar( 255 ) NOT NULL,
	scope_id      bigint         NOT NULL,
	allowed       boolean        NOT NULL DEFAULT false,

	CONSTRAINT `oauth2_client_scope__client_id` FOREIGN KEY ( `client_id` )
		REFERENCES `oauth2_client` ( `id` )
		ON UPDATE CASCADE ON DELETE CASCADE,

	CONSTRAINT `oauth2_client_scope__scope_id` FOREIGN KEY ( `scope_id` )
		REFERENCES `oauth2_scope` ( `id` )
		ON UPDATE CASCADE ON DELETE CASCADE,

	PRIMARY KEY( client_id, scope_id )
);

create table if not exists oauth2_auth_code (
	auth_code            varchar( 255 ) NOT NULL PRIMARY KEY,
	client_id            varchar( 255 ) NOT NULL,
	user_id              integer( 20 ) DEFAULT NULL,
	expires              timestamp NOT NULL,
	redirect_uri         tinytext NOT NULL,
	verified             boolean NOT NULL DEFAULT false,

	CONSTRAINT `oauth2_auth_code__client_id`
		FOREIGN KEY ( `client_id` )
		REFERENCES `oauth2_client` ( `id` )
		ON UPDATE CASCADE ON DELETE CASCADE,

	CONSTRAINT `oauth2_auth_code__user_id`
		FOREIGN KEY ( `user_id` )
		REFERENCES `user` ( `id` )
		ON UPDATE CASCADE ON DELETE CASCADE
);

create table if not exists oauth2_auth_code_scope (
	auth_code     varchar( 255 ) NOT NULL,
	scope_id      bigint         NOT NULL,
	allowed       boolean        NOT NULL DEFAULT false,

	CONSTRAINT `oauth2_auth_code_scope__auth_code`
		FOREIGN KEY ( `auth_code` )
		REFERENCES `oauth2_auth_code` ( `auth_code` )
		ON UPDATE CASCADE ON DELETE CASCADE,

	CONSTRAINT `oauth2_auth_code_scope__scope_id`
		FOREIGN KEY ( `scope_id` )
		REFERENCES `oauth2_scope` ( `id` )
		ON UPDATE CASCADE ON DELETE CASCADE,

	PRIMARY KEY( auth_code, scope_id )
);

create table if not exists oauth2_access_token (
	access_token         varchar( 255 ) NOT NULL PRIMARY KEY,
	refresh_token        varchar( 255 ) DEFAULT NULL,
	client_id            varchar( 255 ) NOT NULL,
	user_id              integer( 20 ) DEFAULT NULL,
	expires              timestamp NOT NULL,

	CONSTRAINT `oauth2_access_token__client_id`
		FOREIGN KEY ( `client_id` )
		REFERENCES `oauth2_client` ( `id` )
		ON UPDATE CASCADE ON DELETE CASCADE,

	CONSTRAINT `oauth2_access_token__user_id`
		FOREIGN KEY ( `user_id` )
		REFERENCES `user` ( `id` )
		ON UPDATE CASCADE ON DELETE CASCADE
);

create table if not exists oauth2_access_token_scope (
	access_token  varchar( 255 ) NOT NULL,
	scope_id      bigint         NOT NULL,
	allowed       boolean        NOT NULL DEFAULT false,

	CONSTRAINT `oauth2_access_token_scope__auth_code`
		FOREIGN KEY ( `access_token` )
		REFERENCES `oauth2_access_token` ( `access_token` )
		ON UPDATE CASCADE ON DELETE CASCADE,

	CONSTRAINT `oauth2_access_token_scope__scope_id`
		FOREIGN KEY ( `scope_id` )
		REFERENCES `oauth2_scope` ( `id` )
		ON UPDATE CASCADE ON DELETE CASCADE,

	PRIMARY KEY( access_token, scope_id )
);

create table if not exists oauth2_refresh_token (
	refresh_token        varchar( 255 ) NOT NULL PRIMARY KEY,
	access_token         varchar( 255 ) NOT NULL,
	client_id            varchar( 255 ) NOT NULL,
	user_id              integer( 20 ) DEFAULT NULL,

	CONSTRAINT `oauth2_refresh_token__client_id`
		FOREIGN KEY ( `client_id` )
		REFERENCES `oauth2_client` ( `id` )
		ON UPDATE CASCADE ON DELETE CASCADE,

	CONSTRAINT `oauth2_refresh_token__user_id`
		FOREIGN KEY ( `user_id` )
		REFERENCES `user` ( `id` )
		ON UPDATE CASCADE ON DELETE CASCADE
);

create table if not exists oauth2_refresh_token_scope (
	refresh_token varchar( 255 ) NOT NULL,
	scope_id      bigint         NOT NULL,
	allowed       boolean        NOT NULL DEFAULT false,

	CONSTRAINT `oauth2_refresh_token_scope__auth_code`
		FOREIGN KEY ( `refresh_token` )
		REFERENCES `oauth2_refresh_token` ( `refresh_token` )
		ON UPDATE CASCADE ON DELETE CASCADE,

	CONSTRAINT `oauth2_refresh_token_scope__scope_id`
		FOREIGN KEY ( `scope_id` )
		REFERENCES `oauth2_scope` ( `id` )
		ON UPDATE CASCADE ON DELETE CASCADE,

	PRIMARY KEY( refresh_token, scope_id )
);
