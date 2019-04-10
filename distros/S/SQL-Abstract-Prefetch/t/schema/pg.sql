
CREATE TYPE access_level AS ENUM ( 'user', 'moderator', 'admin' );
CREATE TABLE people (
    id SERIAL PRIMARY KEY,
    name VARCHAR NOT NULL,
    email VARCHAR,
    age INTEGER,
    contact BOOLEAN,
    phone VARCHAR(50)
);
CREATE TABLE "user" (
    id SERIAL PRIMARY KEY,
    username VARCHAR UNIQUE NOT NULL,
    email VARCHAR NOT NULL,
    password VARCHAR NOT NULL,
    access access_level NOT NULL DEFAULT 'user',
    age INTEGER DEFAULT NULL
);
CREATE TABLE blog (
    id SERIAL PRIMARY KEY,
    user_id INTEGER,
    title TEXT NOT NULL,
    slug TEXT,
    markdown TEXT NOT NULL,
    html TEXT,
    is_published BOOLEAN NOT NULL DEFAULT FALSE,
    FOREIGN KEY (user_id) REFERENCES "user" (id) ON DELETE CASCADE
);
CREATE TABLE IF NOT EXISTS mojo_migrations (
    name TEXT UNIQUE NOT NULL,
    version BIGINT NOT NULL CHECK (version >= 0)
);
CREATE TABLE "comment" (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    blog_id INTEGER NOT NULL,
    markdown TEXT NOT NULL,
    html TEXT,
    FOREIGN KEY (user_id) REFERENCES "user" (id) ON DELETE CASCADE,
    FOREIGN KEY (blog_id) REFERENCES "blog" (id) ON DELETE CASCADE
);
