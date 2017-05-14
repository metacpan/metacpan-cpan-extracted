/* ============================================================ */
/*   Database name:  pqweb                                      */
/*   DBMS name:      Microsoft SQL Server 6.x                   */
/*   Created on:     3/18/98  2:45 PM                           */
/* ============================================================ */

/* */
/* pqweb database for use with the pqedit.cgi script.  This database is optional. */
/* This mssql_pqweb.sql DDL script assumes you have created and sized a database with the name pqweb. */
/* To use this script make sure that the isql program is in your path and configured properly and then run: */
/*      isql -Sserver_name -Usa -i mssql_pqweb.sql */
/* Note: sa may be replaced with the owner of the pqweb database */
/* 3/18/98  2:45 PM -- Brian H. Dunford-Shore */
/* */
use pqweb
go

if exists (select 1
            from  sysindexes
           where  id    = object_id('pq_webvalues')
            and   name  = 'PK_PQ_WEB'
            and   indid > 0
            and   indid < 255)
   drop index pq_webvalues.PK_PQ_WEB
go

if exists (select 1
            from  sysobjects
           where  name = 'pq_webvalues'
            and   type = 'U')
   drop table pq_webvalues
go

if exists (select 1
            from  sysindexes
           where  id    = object_id('pq_noshow')
            and   name  = 'PK_PQ_NOSHOW'
            and   indid > 0
            and   indid < 255)
   drop index pq_noshow.PK_PQ_NOSHOW
go

if exists (select 1
            from  sysobjects
           where  name = 'pq_noshow'
            and   type = 'U')
   drop table pq_noshow
go

if exists (select 1
            from  sysindexes
           where  id    = object_id('pq_labels')
            and   name  = 'PK_PQ_LABELS'
            and   indid > 0
            and   indid < 255)
   drop index pq_labels.PK_PQ_LABELS
go

if exists (select 1
            from  sysobjects
           where  name = 'pq_labels'
            and   type = 'U')
   drop table pq_labels
go

if exists (select 1
            from  sysindexes
           where  id    = object_id('pqweb')
            and   name  = 'PK_PQWEB'
            and   indid > 0
            and   indid < 255)
   drop index pqweb.PK_PQWEB
go

if exists (select 1
            from  sysobjects
           where  name = 'pqweb'
            and   type = 'U')
   drop table pqweb
go

if exists (select 1
            from  sysindexes
           where  id    = object_id('web_property')
            and   name  = 'PK_WEB_PROPERTY'
            and   indid > 0
            and   indid < 255)
   drop index web_property.PK_WEB_PROPERTY
go

if exists (select 1
            from  sysobjects
           where  name = 'web_property'
            and   type = 'U')
   drop table web_property
go

if exists (select 1
            from  sysindexes
           where  id    = object_id('web_elements')
            and   name  = 'PK_WEB_ELEMENTS'
            and   indid > 0
            and   indid < 255)
   drop index web_elements.PK_WEB_ELEMENTS
go

if exists (select 1
            from  sysobjects
           where  name = 'web_elements'
            and   type = 'U')
   drop table web_elements
go

if exists (select 1
            from  sysindexes
           where  id    = object_id('result_types')
            and   name  = 'PK_RESULT_TYPES'
            and   indid > 0
            and   indid < 255)
   drop index result_types.PK_RESULT_TYPES
go

if exists (select 1
            from  sysobjects
           where  name = 'result_types'
            and   type = 'U')
   drop table result_types
go

if exists(select 1 from dbo.systypes where name ='T_field_name')
  execute sp_droptype T_field_name
go

execute sp_addtype T_field_name, 'varchar(50)', 'null'
go

if exists(select 1 from dbo.systypes where name ='T_pq_result')
  execute sp_droptype T_pq_result
go

execute sp_addtype T_pq_result, 'varchar(50)', 'null'
go

if exists(select 1 from dbo.systypes where name ='T_table_name')
  execute sp_droptype T_table_name
go

execute sp_addtype T_table_name, 'varchar(120)', 'null'
go

if exists(select 1 from dbo.systypes where name ='T_web_elements')
  execute sp_droptype T_web_elements
go

execute sp_addtype T_web_elements, 'smallint', 'null'
go

/* ============================================================ */
/*   Table: result_types                                        */
/* ============================================================ */
create table result_types
(
    result_enum           smallint              not null,
    result_name           varchar(255)          not null,
    constraint PK_RESULT_TYPES primary key (result_enum)
)
go

/* ============================================================ */
/*   Table: web_elements                                        */
/* ============================================================ */
create table web_elements
(
    web_elements          T_web_elements        not null,
    element_description   varchar(255)          not null,
    constraint PK_WEB_ELEMENTS primary key (web_elements)
)
go

/* ============================================================ */
/*   Table: web_property                                        */
/* ============================================================ */
create table web_property
(
    web_property          varchar(50)           not null,
    property_description  varchar(255)          null    ,
    constraint PK_WEB_PROPERTY primary key (web_property)
)
go

/* ============================================================ */
/*   Table: pqweb                                               */
/* ============================================================ */
create table pqweb
(
    pq                    T_pq_result           not null,
    result_enum           smallint              not null,
    helppage              varchar(255)          not null,
    accumulate_keys       smallint              null    ,
    constraint PK_PQWEB primary key (pq)
)
go

/* ============================================================ */
/*   Table: pq_labels                                           */
/* ============================================================ */
create table pq_labels
(
    pq                    T_pq_result           not null,
    field_name            T_field_name          not null,
    label                 varchar(255)          not null,
    constraint PK_PQ_LABELS primary key (pq, field_name)
)
go

/* ============================================================ */
/*   Table: pq_noshow                                           */
/* ============================================================ */
create table pq_noshow
(
    pq                    T_pq_result           null    ,
    noshow_field          T_field_name          not null,
    constraint PK_PQ_NOSHOW primary key (noshow_field)
)
go

/* ============================================================ */
/*   Table: pq_webvalues                                        */
/* ============================================================ */
create table pq_webvalues
(
    pq                    T_pq_result           not null,
    web_elements          T_web_elements        not null,
    web_property          varchar(50)           not null,
    web_value             varchar(255)          not null,
    constraint PK_PQ_WEB primary key (pq, web_elements, web_property)
)
go

alter table pqweb
    add constraint FK_PQWEB_REF_15_RESULT_T foreign key  (result_enum)
       references result_types (result_enum)
go

alter table pq_labels
    add constraint FK_PQ_LABEL_REF_135_PQWEB foreign key  (pq)
       references pqweb (pq)
go

alter table pq_noshow
    add constraint FK_PQ_NOSHO_REF_141_PQWEB foreign key  (pq)
       references pqweb (pq)
go

alter table pq_webvalues
    add constraint FK_PQ_WEB_REF_183_PQWEB foreign key  (pq)
       references pqweb (pq)
go

alter table pq_webvalues
    add constraint FK_PQ_WEB_REF_187_WEB_ELEM foreign key  (web_elements)
       references web_elements (web_elements)
go

alter table pq_webvalues
    add constraint FK_PQ_WEB_REF_191_WEB_PROP foreign key  (web_property)
       references web_property (web_property)
go

