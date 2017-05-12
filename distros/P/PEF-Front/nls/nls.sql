create table nls_lang (
    short        char(2)   primary key,
    name         text      not null unique,
    alternative  char(2)   default 'en',
    nplurals     integer   not null default 2,
    plural_forms text      not null default '$n != 1',
    is_active    boolean   not null default false
);

create table nls_geo (
    country   char(2)   primary key,
    short     char(2)   not null references nls_lang(short)
);

create table nls_msgid (
    id_nls_msgid     serial       primary key,
    msgid            text         not null,
    msgid_plural     text,
    context          text,
    unique(msgid, context),
    unique(msgid_plural, context)
);

create table nls_message (
    id_nls_msgid    integer     not null references nls_msgid(id_nls_msgid) on delete cascade,
    short           char(2)     not null references nls_lang(short) on delete cascade,
    message_json    text        not null,
    unique (id_nls_msgid, short)
);

create index i_nls_message_short_id_nls_msgid on nls_message (short,id_nls_msgid);
create index i_nls_msgid_msgid on nls_msgid (msgid);
create index i_nls_msgid_msgid_context on nls_msgid (msgid,context);
create index i_nls_msgid_msgid_plural_context on nls_msgid (msgid_plural,context);
create index i_nls_geo_short on nls_geo (short);
