/* 
 * The contents of this file are subject to the Mozilla Public
 * License Version 1.1 (the "License"); you may not use this file
 * except in compliance with the License. You may obtain a copy of
 * the License at http://www.mozilla.org/MPL/
 * 
 * Software distributed under the License is distributed on an "AS
 * IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or
 * implied. See the License for the specific language governing
 * rights and limitations under the License.
 * 
 * The Original Code is the rdf_pgsql.sql
 * 
 * The Initial Developer of the Original Code is Ginger Alliance Ltd.
 * Portions created by Ginger Alliance are 
 * Copyright (C) 2001 Ginger Alliance Ltd.
 * All Rights Reserved.
 * 
 * Contributor(s):
 * 
 * Alternatively, the contents of this file may be used under the
 * terms of the GNU General Public License Version 2 or later (the
 * "GPL"), in which case the provisions of the GPL are applicable 
 * instead of those above.  If you wish to allow use of your 
 * version of this file only under the terms of the GPL and not to
 * allow others to use your version of this file under the MPL,
 * indicate your decision by deleting the provisions above and
 * replace them with the notice and other provisions required by
 * the GPL.  If you do not delete the provisions above, a recipient
 * may use your version of this file under either the MPL or the
 * GPL.
 */ 

-- ========================================
--
--  Database model for RDF::Core
--  
--  Postgres with Pl/PgSQL version.
--
-- ========================================

-- ========================================
--   RDF NAMESPACE
-- ========================================

\echo => RDF NAMESPACE

create table rdf_namespace (
   ns_id integer not null,
   namespace text,
   primary key (ns_id)
);   

create sequence rdf_namespace_seq;

create unique index rdf_namespace_idx_name on rdf_namespace (namespace);

create function rdf_ns_new(text)
  returns integer
  /* $1 : new namespace 
   * ret: new namespace id 
   *
   * creates new namespace item in enumeration
   * no explicite check for duplicities
   * implicit check by index rdf_namespace_idx_name
   */
  as
  ' DECLARE
      rval integer;
    BEGIN
      rval = nextval(''rdf_namespace_seq'');
      insert into rdf_namespace values (rval, $1);
      return rval;
    END;'
  language 'plpgsql';  

create function rdf_ns_get(text, integer)
  returns integer
  /* $1: namespace
   * $2: [0,1] - if namespace does not exist
   *      0 = do not create new namespace
   *      1 = create new namespace
   * returns namespace id or negative error code
   *   -1 : namespace does not exist
   */
  as
  ' DECLARE
      rval integer;
    BEGIN
      select ns_id into rval from rdf_namespace
        where namespace = $1;
      rval = coalesce(rval,-1);	
      if ((rval = -1) and ($2 = 1)) then
	  rval = rdf_ns_new($1);
      end if;
      return rval;
    END;'
  language 'plpgsql';

-- ========================================
-- RDF RESOURCE
-- ========================================

\echo => RDF RESOURCE

create table rdf_resource (
   res_id integer not null,
   ns_id integer not null,
   local_name text not null,
   primary key (res_id)
);

-- resource id sequence
create sequence rdf_resource_seq;

-- resource uniqueness and search
create unique index rdf_resource_idx_name on rdf_resource 
  (ns_id, local_name);


-- namespace must exist
create function rdf_res_tbiup()
  returns opaque
  as 
  ' DECLARE
      dummy integer;
      op text;
    BEGIN
      select ns_id into dummy from rdf_namespace where
        ns_id = new.ns_id;
      if (dummy is null) then
        op = lower(tg_op);
        raise exception ''[%; %]: can''''t set resource namespace id to %; the namespace does not exist.'', tg_relname, op, new.ns_id;
        return null; /* not necessary, but nice :) */
      else
        return new;
      end if;
    END;'
  language 'plpgsql';

create trigger rdf_res_tbiu 
  before insert or update 
  on rdf_resource
  for each row 
  execute procedure rdf_res_tbiup();


-- interface functions to manipulate data

create function rdf_res_new(integer,text)
  returns integer
  /* $1: namespace id
   * $2: local name
   * returns new resource id
   *
   * the function does not check namespace existence
   *   the check is on forein constraint (if the constraint exists)
   * the function does not check resource existence
   *   implicite check by index rdf_resource_idx_name
   */
  as
  ' DECLARE
      rval integer;
    BEGIN
      rval = nextval(''rdf_resource_seq'');
      insert into rdf_resource values (rval, $1, $2);
      return rval;
    END;'
  language 'plpgsql';  

create function rdf_res_new(text,text)
  returns integer
  /* $1: namespace
   * $2: local name
   * returns 
   *   new resource id
   *
   * the function checks namespace existence
   *   if namespace does not exists, it returns error -1
   * the function does not check resource existence
   *   implicite check by index rdf_resource_idx_name
   */
  as
  ' DECLARE
      rval integer;
      ns integer;
    BEGIN
      rval = rdf_res_new(rdf_ns_get($1,1), $2);
      return rval;
    END;'
  language 'plpgsql';  

create function rdf_res_get(integer,text,integer)
  returns integer
  /* $1: namespace
   * $2: local name
   * $3: switch [0,1]
   *      0: do not create new resource if does not exist
   *      1: create new resource if does not exist
   * returns 
   *   resource id or negative error number
   *     -1: resource does not exist
   */
  as
  ' DECLARE
      rval integer;
    BEGIN
      select res_id into rval from rdf_resource where 
        ns_id = $1 and local_name = $2;
      rval = coalesce(rval,-1);
      if ((rval = -1) and ($3 = 1)) then /* create new resource */
        rval = rdf_res_new($1, $2);   
      end if;	      
      return rval;
    END;'
  language 'plpgsql';  

create function rdf_res_get(text,text,integer)
  returns integer
  /* $1: namespace
   * $2: local name
   * $3: switch [0,1]
   *      0: do not create new resource or namespace if they do not exist
   *      1: create new resource and namespace, if they do not exist
   * returns 
   *   resource id or negative error number
   *     -1: resource does not exist
   *     -2: namespace does not exist
   */
  as
  ' DECLARE
      rval integer;
      ns integer;
      dummy integer;
    BEGIN
      ns = rdf_ns_get($1, $3);
      if (ns = -1) then  /* namespace does not exist */
        rval = -2; 
      else
        rval = rdf_res_get(ns,$2,$3);
      end if;
      return rval;
    END;'
  language 'plpgsql';  


-- ========================================
--  RDF MODEL
-- ========================================

create table rdf_model (
  model_id integer,
  model text,
  description text,
  primary key (model_id)
);

create sequence rdf_model_seq;

-- enforce unique model name
create unique index rdf_model_idx_model on rdf_model (model);

create function rdf_model_new(text,text)
  returns integer
  as
  'DECLARE
     rval integer;
   BEGIN
     rval = nextval(''rdf_model_seq'');
     insert into rdf_model values (rval, $1, $2);
     return rval;
   END;'
  language 'plpgsql';

-- create default model
\echo create default model
select rdf_model_new('Default model', 'Default model: DO NOT DELETE');

create function rdf_model_get(text,integer)
  returns integer
  /* function return model id from model name
   * $1: model name
   * $2: [0,1] flag
   *     0: do not create new model if does not exist
   *	 1: create new model if does not exist
   * return: respective model id
   */ 
  as
  'DECLARE
     rval integer;
   BEGIN
     select model_id into rval from rdf_model 
       where model = $1;
     if ((rval is null) and ($2 = 1)) then
	rval = rdf_model_new($1, ''Comment: '' || $1);
     end if;
     return coalesce(rval,-1);
   END;'
  language 'plpgsql';

-- ========================================
--  RDF STATEMENT
-- ========================================

create table rdf_statement (
   model_id integer not null default 1,
   stmt_id integer not null,
   subject integer not null,
   predicate integer not null,
   object_res integer,
   object_lit text,
   object_lang text,
   object_type text,
   primary key (stmt_id)
);

create sequence rdf_statement_seq;

-- indexes

create index rdf_statement_idx_model on rdf_statement (model_id);
create index rdf_statement_idx_s on rdf_statement (model_id, subject);
create index rdf_statement_idx_p on rdf_statement (model_id, predicate);
create index rdf_statement_idx_or on rdf_statement (model_id, object_res);
create index rdf_statement_idx_ol on rdf_statement (model_id, object_lit);

create index rdf_statement_idx_sp on rdf_statement 
  (model_id, subject, predicate);
create index rdf_statement_idx_sor on rdf_statement 
  (model_id, subject, object_res);
create index rdf_statement_idx_sol on rdf_statement 
  (model_id, subject, object_lit);

create index rdf_statement_idx_por on rdf_statement 
  (model_id, predicate, object_res);
create index rdf_statement_idx_pol on rdf_statement 
  (model_id, predicate, object_lit);

create index rdf_statement_idx_spor on rdf_statement
  (model_id,subject,predicate,object_res);
create index rdf_statement_idx_spol on rdf_statement
  (model_id,subject,predicate,object_lit);

-- enforce integrity and uniqueness

-- helper local methods used internally in the constraint trigger
create function rdf_stmt_err0(text,text,integer)
  returns integer
  as
  'DECLARE
     op text;
     oped text;
   BEGIN
     op = lower($2);
     raise exception 
       ''[%; %]: model [%] does not exist.'', 
       $1,op,$3;
     return null;
   END;'
  language 'plpgsql';

create function rdf_stmt_err1(text,text,text,integer)
  returns integer
  as
  'DECLARE
     op text;
     oped text;
   BEGIN
     op = lower($2);
     raise exception 
       ''[%; %]: statement % [%] does not exist.'', 
       $1,op,$3,$4;
     return null;
   END;'
  language 'plpgsql';

create function rdf_stmt_err2(text,text,integer)
  returns integer
  as
  'DECLARE
     op text;
   BEGIN
     op = lower($2);
     raise exception 
       ''[%; %]: statement is duplicate of statement [%].'', 
         $1, op, $3;
     return null;   
   END;'
  language 'plpgsql';

create function rdf_stmt_err3(text,text,integer)
  returns integer
  as
  'DECLARE
     op text;
     err text;
   BEGIN
     op = lower($2);
     if ($3 = 1) then
       err = ''has no object'';
     else 
       if ($3 = 2) then
         err = ''has both resource and literal objects'';
       end if;
     end if;
     raise exception 
       ''[%; %]: statement %.'', 
       $1, op, err;
     return null;   
   END;'
  language 'plpgsql';

create function rdf_stmt_tbiup()
  returns opaque 
  as
  'DECLARE
     dummy integer;
     e integer;
   BEGIN
     /* model must exist */ 
     select model_id into dummy from rdf_model 
       where model_id = new.model_id;
     if (dummy is null) then
        e = rdf_stmt_err0(tg_relname, tg_op, new.model_id);
     end if;     
     /* resources must exist */
     select res_id into dummy from rdf_resource 
       where res_id = new.subject;
     if (dummy is null) then
        e = rdf_stmt_err1(tg_relname, tg_op, ''subject'', new.subject);
     end if;
     select res_id into dummy from rdf_resource 
       where res_id = new.predicate;
     if (dummy is null) then
        e = rdf_stmt_err1(tg_relname, tg_op, ''predicate'', new.predicate);
     end if;
     if (new.object_res is not null) then
       select res_id into dummy from rdf_resource 
         where res_id = new.object_res;
       if (dummy is null) then
         e = rdf_stmt_err1(tg_relname, tg_op, ''object'', new.object_res);
       end if;
     end if;
     /* statement integrity and uniqueness */
     if ((new.object_res is null) and (new.object_lit is null)) then
         e = rdf_stmt_err3(tg_relname, tg_op, 1);
     else 
       if ((new.object_res is not null) and (new.object_lit is not null)) then
         e = rdf_stmt_err3(tg_relname, tg_op, 2);
       else 
         if (new.object_res is not null) then
           select stmt_id into dummy from rdf_statement where 
	     model_id = new.model_id and subject = new.subject and 
	     predicate = new.predicate and object_res = new.object_res;
           if (dummy is not null) then
	     e = rdf_stmt_err2(tg_relname, tg_op, dummy);
           end if;
         else
           if (new.object_lit is not null) then     
             select stmt_id into dummy from rdf_statement where 
	       model_id = new.model_id and subject = new.subject and 
	       predicate = new.predicate and object_lit = new.object_lit and 
	       (object_lang = new.object_lang or 
		 object_lang is null and new.object_lang is null) and 
	       (object_type = new.object_type or 
		 object_type is null and new.object_type is null) ;
             if (dummy is not null) then
	       e = rdf_stmt_err2(tg_relname, tg_op, dummy);
             end if; 
           end if;
         end if;
       end if;
     end if;
     return new;
   END;'
  language 'plpgsql'; 

create trigger rdf_stmt_tbiu 
  before insert or update 
  on rdf_statement
  for each row 
  execute procedure rdf_stmt_tbiup();


create function rdf_stmt_new(integer,integer,integer,integer)
  returns integer
  /* $1: model id
   * $2: subject resource id
   * $3: predicate resource id
   * $4: object resource id
   * returns: new resource id
   * 
   * no check for uniqueness (check is on other constraints)
   */
  as
  ' DECLARE
      rval integer;
    BEGIN
      rval = nextval(''rdf_statement_seq'');
      insert into rdf_statement values ($1,rval,$2,$3,$4);
      return rval;
    END;'
  language 'plpgsql';

create function rdf_stmt_new(integer,integer,text,
  integer,text,integer,text)
  returns integer
   /* $1: model id
    * $2: subject namespace id
    * $3: subject local name
    * $4: predicate resource id
    * $5: predicate local name
    * $6: object namespace id
    * $7: object local name
    * returns: new resource id
    * 
    * no check (check is on other constraints)
    */
  as
  ' DECLARE
      subj integer;
      pred integer;
      obj integer;
    BEGIN
      subj = rdf_res_get($2,$3,1);
      pred = rdf_res_get($4,$5,1);
      obj = rdf_res_get($6,$7,1);
      return rdf_stmt_new($1,subj,pred,obj);
    END;'
  language 'plpgsql';

create function rdf_stmt_new(integer,text,text,text,text,text,text)
  returns integer
   /* $1: model id
    * $2: subject namespace
    * $3: subject local name
    * $4: predicate resource
    * $5: predicate local name
    * $6: object namespace
    * $7: object local name
    * returns: new resource id
    * 
    * no check  for uniqueness (check is on other constraints)
    */
  as
  ' DECLARE
      subj integer;
      pred integer;
      obj integer;
    BEGIN
       subj = rdf_res_get($2,$3,1);
       pred = rdf_res_get($4,$5,1);
       obj = rdf_res_get($6,$7,1);
       return rdf_stmt_new($1,subj,pred,obj);
    END;'
  language 'plpgsql';


create function rdf_stmt_get(integer,integer,integer,integer,integer)
  returns integer
  as
  /* $1: model id
   * $2: subject resource id
   * $3: predicate resource id
   * $4: object resource id
   * $5: switch [0,1]
   *       0: do not create statement, if it does not exist
   *       1: create statement if it does not exist  
   * returns: statement id
   * 
   * no check for uniqueness (check is on other constraints)
   */
  ' DECLARE
      rval integer;
    BEGIN
      select stmt_id into rval from rdf_statement
        where model_id = $1 and subject = $2 and predicate = $3 and
	      object_res = $4;
      rval = coalesce(rval,-1);
      if ((rval = -1) and ($5 = 1)) then /* create new statement */
        rval = rdf_stmt_new($1,$2,$3,$4);
      end if;
      return rval;
    END;'
  language 'plpgsql';

create function rdf_stmt_get(integer,text,text,text,text,text,text,integer)
  returns integer
   /* $1: model id
    * $2: subject namespace
    * $3: subject local name
    * $4: predicate resource
    * $5: predicate local name
    * $6: object namespace
    * $7: object local name
    * returns: new resource id
    * 
    * no check  for uniqueness (check is on other constraints)
    */
  as
  ' DECLARE
      rval integer;
      subj integer;
      pred integer;
      obj integer;
    BEGIN
      rval = -1; 
      subj = rdf_res_get($2,$3,$8);
      pred = rdf_res_get($4,$5,$8);
      obj = rdf_res_get($6,$7,$8);
      if ((subj > 0) and (pred > 0) and (obj > 0)) then
        rval = rdf_stmt_get($1,subj,pred,obj,$8);
      end if;
      return rval;
    END;'
  language 'plpgsql';

-- statements with literals function

create function rdf_stmt_new(integer,integer,integer,text, text, text)
  returns integer
  /* $1: model id
   * $2: subject resource id
   * $3: predicate resource id
   * $4: object literal
   * $5: object language
   * $6: object datatype
   * returns: new resource id
   * 
   * no check for uniqueness (check is on other constraints)
   */
  as
  ' DECLARE
      rval integer;
    BEGIN
      rval = nextval(''rdf_statement_seq'');
      insert into rdf_statement values ($1,rval,$2,$3,null,$4,$5,$6);
      return rval;
    END;'
  language 'plpgsql';

create or replace function rdf_stmt_get(integer,integer,integer,text,text,text,integer)
  returns integer
  /* $1: model id
   * $2: subject resource id
   * $3: predicate resource id
   * $4: object literal
   * $5: object language
   * $6: object datatype
   * $7: switch [0,1]
   *       0: do not create staement, if it does not exist
   *       1: create statement if it does not exist  
   * returns: new resource id
   * 
   * no check for uniqueness (check is on other constraints)
   */
  as
  ' DECLARE
      rval integer;
    BEGIN
      select stmt_id into rval from rdf_statement
        where model_id = $1 and subject = $2 and predicate = $3 and
	  object_lit = $4 and 
	  (object_lang = $5 or object_lang is null and $5 is null) and 
	  (object_type = $6 or object_type is null and $6 is null) ;
      rval = coalesce(rval,-1);
      if ((rval = -1) and ($7 = 1)) then /* create new statement */
        rval = rdf_stmt_new($1,$2,$3,$4,$5,$6);
      end if;
      return rval;
    END;'
  language 'plpgsql';

create function rdf_stmt_get(integer,text,text,text,text,text,text,text,
	integer)
  returns integer
   /* $1: model id
    * $2: subject namespace
    * $3: subject local name
    * $4: predicate resource
    * $5: predicate local name
    * $6: object literal
    * $7: object language
    * $8: object datatype
    * $9:  switch [0,1]
    *       0: do not create statement, if it does not exist
    *       1: create statement if it does not exist  
    * returns: new resource id
    * 
    * no check  for uniqueness (check is on other constraints)
    */
  as
  ' DECLARE
      rval integer;
      subj integer;
      pred integer;
    BEGIN
      rval = -1; 
      subj = rdf_res_get($2,$3,$9);
      pred = rdf_res_get($4,$5,$9);
      if ((subj > 0) and (pred > 0)) then
        rval = rdf_stmt_get($1,subj,pred,$6,$7,$8,$9);
      end if;
      return rval;
    END;'
  language 'plpgsql';

-- create function rdf_stmt_del(integer,integer)
--   returns integer
--   as
--   'BEGIN
--      delete from rdf_statement where model_id = $1 and stmt_id = $2;
--      return 1;
--    END;'
--   language 'plpgsql';

create function rdf_stmt_del(integer,integer,integer,integer)
  returns integer
  as
  'BEGIN
     delete from rdf_statement where 
       model_id = $1 and 
       subject = $2 and predicate = $3 and object_res = $4;
     return 1; 
   END;'
  language 'plpgsql';

create function rdf_stmt_del(integer,integer,integer,text, text, text)
  returns integer
  as
  'BEGIN
     delete from rdf_statement where 
       model_id = $1 and 
       subject = $2 and predicate = $3 and object_lit = $4 and 
       (object_lang = $5 or object_lang is null and $5 is null) and 
       (object_type = $6 or object_type is null and $6 is null);
     return 1; 
   END;'
  language 'plpgsql';

-- create function rdf_stmt_del(integer,integer,text,integer,text,integer,text)
--   returns integer
--   as
--   'DECLARE
--      rval integer;
--      subj integer;
--      pred integer; 
--      obj integer;
--    BEGIN
--      subj = rdf_res_get($2,$3,0);
--      pred = rdf_res_get($4,$5,0);
--      obj = rdf_res_get($6,$7,0);
--      if ((subj > 0) and (pred > 0) and (obj > 0)) then
--        rval = rdf_stmt_del($1, subj,pred,obj);
--      end if;  
--      return rval; 
--    END;'
--   language 'plpgsql';

-- create function rdf_stmt_del(integer,integer,text,integer,text,text)
--   returns integer
--   as
--   'DECLARE
--      rval integer;
--      subj integer;
--      pred integer; 
--    BEGIN
--      subj = rdf_res_get($2,$3,0);
--      pred = rdf_res_get($4,$5,0);
--      if ((subj > 0) and (pred > 0)) then
--        rval = rdf_stmt_del($1, subj,pred,$6);
--      end if;  
--      return rval; 
--    END;'
--   language 'plpgsql';


create function rdf_stmt_del(integer,text,text,text,text,text,text)
  returns integer
  as
  'DECLARE
     rval integer;
     subj integer;
     pred integer; 
     obj integer;
   BEGIN
     subj = rdf_res_get($2,$3,0);
     pred = rdf_res_get($4,$5,0);
     obj = rdf_res_get($6,$7,0);
     if ((subj > 0) and (pred > 0) and (obj > 0)) then
       rval = rdf_stmt_del($1, subj,pred,obj);
     end if;  
     return rval; 
   END;'
  language 'plpgsql';

create function rdf_stmt_del(integer,text,text,text,text,text,text,text)
  returns integer
  as
  'DECLARE
     rval integer;
     subj integer;
     pred integer; 
   BEGIN
     subj = rdf_res_get($2,$3,0);
     pred = rdf_res_get($4,$5,0);
     if ((subj > 0) and (pred > 0)) then
       rval = rdf_stmt_del($1, subj,pred,$6, $7, $8);
     end if;  
     return rval; 
   END;'
  language 'plpgsql';

/* ========================================  */

/* some usefull methods */

-- next couple of methods return standartized namespaces and resources
-- see. http://w3.org/1999/02/22-rdf-syntax-ns

create function rdfns_text() returns text as
  'BEGIN return ''http://w3.org/1999/02/22-rdf-syntax-ns#'';END;'
  language 'plpgsql';

create function rdfns() returns integer as
  'BEGIN return rdf_ns_get(''http://w3.org/1999/02/22-rdf-syntax-ns#'',1);END;'
  language 'plpgsql';

create function rdfns_type() returns integer as
  'BEGIN return rdf_res_get(rdfns(),''type'',1); END;' 
  language 'plpgsql';

create function rdfns_Statement() returns integer as
  'BEGIN return rdf_res_get(rdfns(),''Statement'',1); END;' 
  language 'plpgsql';

create function rdfns_Property() returns integer as
  'BEGIN return rdf_res_get(rdfns(),''Property'',1); END;' 
  language 'plpgsql';

create function rdfns_Bag() returns integer as
  'BEGIN return rdf_res_get(rdfns(),''Bag'',1); END;' 
  language 'plpgsql';

create function rdfns_Seq() returns integer as
  'BEGIN return rdf_res_get(rdfns(),''Seq'',1); END;' 
  language 'plpgsql';

create function rdfns_Alt() returns integer as
  'BEGIN return rdf_res_get(rdfns(),''Alt'',1); END;' 
  language 'plpgsql';

create function rdfns_subject() returns integer as
  'BEGIN return rdf_res_get(rdfns(),''subject'',1); END;' 
  language 'plpgsql';

create function rdfns_predicate() returns integer as
  'BEGIN return rdf_res_get(rdfns(),''predicate'',1); END;' 
  language 'plpgsql';

create function rdfns_object() returns integer as
  'BEGIN return rdf_res_get(rdfns(),''object'',1); END;' 
  language 'plpgsql';

-- very important functions, returns unique 'anonymous' resources
-- i.e. resources, that have no expolicite URI (e.g. containers)

create sequence rdf_res_new_id_seq minvalue -2147483647 cycle;

create function rdf_res_new_id(integer)
  returns text
  as
  'DECLARE
     rval text;
     dummy integer;
   BEGIN
    dummy = abs(hashname(timeofday()));
    rval = trim(both '' '' from to_char(dummy,repeat(''9'',30)));
    dummy = abs(nextval(''rdf_res_new_id_seq''));    
    rval = rval || trim(both '' '' from to_char(dummy ,repeat(''9'',30)));
    dummy = abs(hashname(timeofday()));
    rval = rval || trim(both '' '' from to_char(dummy,repeat(''9'',30)));
    while (char_length(rval) < 30) loop
      rval = rval || trim(both '' '' from to_char(ceil(random()*9),''99''));
    end loop;  
    rval = substring(rval from 0 for $1);
    select res_id into dummy from rdf_resource where local_name = rval;
    if (dummy is not null) then
      rval = rdf_res_new_id($1);
    end if;  
    return rval;
   END;'
  language 'plpgsql';      


create function rdf_res_new_id()
  returns text
  as
  'BEGIN
    return rdf_res_new_id(30);
   END;'
  language 'plpgsql';      


create function rdf_res_new_anonymous()
  returns integer
  as
  'BEGIN
     return rdf_res_new(''urn:rdf-core:'', rdf_res_new_id()); 
   END;'
  language 'plpgsql';  

-- functions that return resource and statement URI

create function rdf_res_uri(integer)
  returns text
  /* $1: resource id
   * returns resource URI
   */
  as
  'DECLARE
     rval text;
   BEGIN
     select ns.namespace || res.local_name into rval from
       rdf_resource res JOIN rdf_namespace ns ON res.ns_id = ns.ns_id
       where res.res_id = $1;
     return rval;  
   END;'
  language 'plpgsql';

create function rdf_stmt_text(integer,integer)
  returns text
  /* $1: model id
   * $2: statement id
   * returns statement textual representation {p,s,o}
   */
  as
  'DECLARE	
     rval text;
   BEGIN
     select ''{['' || rdf_res_uri(predicate) || ''],['' || rdf_res_uri(subject) || ''],'' || case when object_res is not null then ''['' || rdf_res_uri(object_res) || '']'' else ''"'' || object_lit || ''"'' end ||  ''}'' into rval from rdf_statement where model_id = $1 and stmt_id = $2;
     return rval;
   END;'
  language 'plpgsql'; 

/* ========================================
   *
   * manipulating containers
   *
   ======================================== */

create function rdf_cont_li_number(text)
  returns integer
  /* converts '_xyz' list item local name to number
   * $1 : list item local name in '_xyz' format
   * return : numeric representatnin of the li local name
   */
  as
  'BEGIN
     if (''_'' = substring($1 from 1 for 1)) then
       return to_number(substring($1 from 2 for (length($1)-1)),repeat(''9'',30));
     else 
       return -1;
     end if;
   END;'
   language 'plpgsql';

create function rdf_cont_next_li(integer,integer)
  returns text
  /* get next list item uri for a container 
   *
   * $1: model id
   * $2: container resource id
   * returns next container list item local name in '_xyz' form
   */
  as
  'DECLARE
     rec record;
     rdf_ns integer; 
     maxli integer;
     li integer;
     rval text;
   BEGIN
     maxli = 0;
     for rec in
       select rdf_cont_li_number(r.local_name)
         from rdf_resource r, rdf_statement s 
	 where s.model_id = $1 and s.subject = $2 and 
	       r.res_id = s.predicate and r.ns_id = rdfns() and 
	       r.local_name ~ ''^_[0-9]+''
     loop
       li = rec.rdf_cont_li_number;
       if (li > maxli) then maxli = li; end if;       
     end loop;
     rval = ''_'' || trim(both '' '' from to_char(maxli+1,repeat(''9'',30)));
     return rval;
   END;'
  language 'plpgsql';

create function rdf_cont_next_li(integer,text,text,text,text)
  returns text
  /* get next list item uri for a container 
   *
   * $1: model id
   * $2: subject namespace
   * $3: subject local name
   * $4: predicate namespace
   * $5: predicate name
   * returns next container list item local name '_xyz'
   *
   * - the subject is resource, to which is the container attached
   * - the predicate identifies the container
   */   
  as
  'DECLARE     
     rval text;
     cont integer;
   BEGIN       
     select 
         s.object_res into cont
       from 
	 rdf_statement s,
	 rdf_namespace n1, rdf_resource r1,
         rdf_namespace n2, rdf_resource r2
       where
         model_id = $1 and
         n1.namespace = $2 and r1.local_name = $3 and
           r1.ns_id = n1.ns_id and r1.res_id = s.subject and
         n2.namespace = $4 and r2.local_name = $5 and
           r2.ns_id = n2.ns_id and r2.res_id = s.predicate;
      rval = rdf_cont_next_li($1,cont);
      return rval;
   END;'
  language 'plpgsql';

create function rdf_cont_get(integer,text,text,text,text,integer,integer)
  returns integer
  /* add a container
   *
   * $1: model id
   * $2: subject namespace
   * $3: subject local name
   * $4: predicate namespace
   * $5: predicate local name
   * $6: container type
   *	 1 = rdf:Bag
   *	 2 = rdf:Sequence
   *	 3 = rdf:Alternative
   * $7: switch [0,1]
   *     0 = do not create noexisting entities
   *	 1 = create noexisting entities
   * returns id of the container
   *
   *
   * if such a container alredy exists, its id is returned 
   * no check of already existing container type is erforced
   *
   * Result is:
   *  
   * [subject] --[predicate]--> [container]
   *                                |
   *                                 --[rdf:type]--> [rdf:(Bag|Seq|Alt)]
   *
   */
  as
  'DECLARE
    subj integer;
    pred integer;
    cont integer;
    ct integer;
    dummy integer;
   BEGIN
     select 
         s.object_res into cont
       from 
	 rdf_statement s,
	 rdf_namespace n1, rdf_resource r1,
         rdf_namespace n2, rdf_resource r2
       where
         model_id = $1 and
         n1.namespace = $2 and r1.local_name = $3 and
           r1.ns_id = n1.ns_id and r1.res_id = s.subject and
         n2.namespace = $4 and r2.local_name = $5 and
           r2.ns_id = n2.ns_id and r2.res_id = s.predicate;
     if ((cont is null) and ($7 = 1)) then
       subj = rdf_res_get($2,$3,1);
       pred = rdf_res_get($4,$5,1);
       cont = rdf_res_get(''urn:rdf-core:'',rdf_res_new_id(),1);       
       if ($6 = 1) then ct = rdfns_Bag(); end if;
       if ($6 = 2) then ct = rdfns_Seq(); end if;
       if ($6 = 3) then ct = rdfns_Alt(); end if;
       dummy = rdf_stmt_new($1,subj,pred,cont);
       dummy = rdf_stmt_new($1,cont,rdfns_type(),ct);
     end if;	   
     return cont;
   END;'
  language 'plpgsql';


-- reification methods

create function rdf_reif_new(integer,integer,integer,integer) 
  returns integer 
  /* $1: model id
   * $2: subject resource id
   * $3: predicate resource id
   * $4: object resource id
   * returns id of new resource that represents the statement reification
   *
   * note: it does not matter when the statement to be reifified does not exist
   */
  as
  'DECLARE 
     reif_res integer; 
     dummy integer; 
   BEGIN
     reif_res = rdf_res_new_anonymous();
     dummy = rdf_stmt_new($1, reif_res, rdfns_type(), rdfns_Statement());
     dummy = rdf_stmt_new($1, reif_res, rdfns_subject(), $2);
     dummy = rdf_stmt_new($1, reif_res, rdfns_predicate(), $3);
     dummy = rdf_stmt_new($1, reif_res, rdfns_object(), $4);
     return reif_res;
   END;'
  language 'plpgsql';

create function rdf_reif_new(integer,integer,integer,text)
  returns integer
  /* $1: model id
   * $2: subject resource id
   * $3: predicate resource id
   * $4: literal object
   * returns id of new resource that represents the statement reification
   *
   * note: it does not matter when the statement to be reifified does not exist
   */
  as
  'DECLARE 
     reif_res integer; 
     dummy integer; 
   BEGIN
     reif_res = rdf_res_new_anonymous();
     dummy = rdf_stmt_new($1, reif_res, rdfns_type(), rdfns_Statement());
     dummy = rdf_stmt_new($1, reif_res, rdfns_subject(), $2);
     dummy = rdf_stmt_new($1, reif_res, rdfns_predicate(), $3);
     dummy = rdf_stmt_new($1, reif_res, rdfns_object(), $4);
     return reif_res;
   END;'
  language 'plpgsql';

create function rdf_reif_get(integer,integer,integer)
  returns integer
  /* $1: model id
   * $2: statement id
   * $3: switch [0,1]
   *	 0 = does not create reification if does not exist
   *	 1 = create new reification if does not exist
   * returns id of new resource that represents the statement reification
   */
  as
  'DECLARE    
     rval integer;
     stmt_subj integer;
     stmt_pred integer;
     stmt_obj_res integer;
     stmt_obj_lit text;
   BEGIN
     if ($2 > 0) then
       select subject into stmt_subj from rdf_statement 
         where model_id = $1 and stmt_id = $2;
       select predicate into stmt_pred from rdf_statement 
         where model_id = $1 and stmt_id = $2;
       select object_res into stmt_obj_res from rdf_statement 
         where model_id = $1 and stmt_id = $2;
       select object_lit into stmt_obj_lit from rdf_statement
          where model_id = $1 and stmt_id = $2;
       if (stmt_obj_res is null) then
         rval = rdf_reif_get($1,stmt_subj, stmt_pred, stmt_obj_lit, $3);
       else
         rval = rdf_reif_get($1,stmt_subj, stmt_pred, stmt_obj_res, $3);
       end if;
     end if;  
     return coalesce(rval,-1);
   END;'
  language 'plpgsql';
 
create function rdf_reif_get(integer,integer,integer,integer,integer)
  returns integer
  /* $1: model id
   * $2: subject resource id
   * $3: predicate resource id
   * $4: object resource id
   * $5: switch [0,1]
   *	 0 = does not create reification if does not exist
   *	 1 = create new reification if does not exist
   * returns id of new resource that represents the statement reification
   */
  as
  'DECLARE    
     rval integer;
   BEGIN
     select s1.subject into rval from 
       rdf_statement s1
       JOIN rdf_statement s2 
         ON s2.model_id = s1.model_id and s2.subject = s1.subject
       JOIN rdf_statement s3 
         ON s3.model_id = s2.model_id and s3.subject = s2.subject
       JOIN rdf_statement s4 
         ON s4.model_id = s3.model_id and s4.subject = s3.subject
       where 
         s1.model_id = $1 and
	 s1.predicate = rdfns_subject() and s1.object_res = $2 and 
  	 s2.predicate = rdfns_predicate() and s2.object_res = $3 and
  	 s3.predicate = rdfns_object() and s3.object_res = $4 and
  	 s4.predicate = rdfns_type() and s4.object_res = rdfns_Statement();
     if ((rval is null) and ($5 = 1)) then
       /* create reification  */
       rval = rdf_reif_new($1, $2, $3, $4);
     end if;
     return coalesce(rval,-1);
   END;'
  language 'plpgsql';

create function rdf_reif_get(integer,integer,integer,text,integer)
  returns integer
  /* $1: model id
   * $2: subject resource id
   * $3: predicate resource id
   * $4: literal object
   * $5: switch [0,1]
   *	 0 = does not create reification if does not exist
   *	 1 = create new reification if does not exist
   * returns id of new resource that represents the statement reification
   */
  as
  'DECLARE    
     rval integer;
   BEGIN
     select s1.subject into rval from 
       rdf_statement s1
       JOIN rdf_statement s2 
         ON s2.model_id = s1.model_id and s2.subject = s1.subject
       JOIN rdf_statement s3 
         ON s3.model_id = s2.model_id and s3.subject = s2.subject
       JOIN rdf_statement s4 
         ON s4.model_id = s3.model_id and s4.subject = s3.subject
       where 
         s1.model_id = $1 and
	 s1.predicate = rdfns_subject() and s1.object_res = $2 and 
  	 s2.predicate = rdfns_predicate() and s2.object_res = $3 and
  	 s3.predicate = rdfns_object() and s3.object_lit = $4 and
  	 s4.predicate = rdfns_type() and s4.object_res = rdfns_Statement();
     if ((rval is null) and ($5 = 1)) then
       /* create reification  */
       rval = rdf_reif_new($1, $2, $3, $4);
     end if;
     return coalesce(rval,-1);
   END;'
  language 'plpgsql';
 
create function rdf_reif_get(integer,text,text,text,text,text,text,integer)
  returns integer
  /* $1: model id
   * $2: subject resource namespace
   * $3: subject resource local name
   * $4: predicate resource namespace
   * $5: predicate resource local name
   * $6: object resource namespace
   * $7: object resource local name
   * $8: switch [0,1]
   *	 0 = does not create reification if does not exist
   *	 1 = create new reification if does not exist
   * returns id of new resource that represents the statement reification
   */
  as
  'DECLARE    
     rval integer;
     stmt_subj integer;
     stmt_pred integer;
     stmt_obj integer;
   BEGIN
     stmt_subj = rdf_res_get($2,$3,$8);
     stmt_pred = rdf_res_get($4,$5,$8);
     stmt_obj = rdf_res_get($6,$7,$8);
     if ((stmt_obj > 0) and (stmt_pred > 0) and (stmt_obj > 0)) then
       rval = rdf_reif_get($1, stmt_subj, stmt_pred, stmt_obj, $8);
     end if;
     return coalesce(rval,-1);
   END;'
  language 'plpgsql';

create function rdf_reif_get(integer,text,text,text,text,text,integer)
  returns integer
  /* $1: model id
   * $2: subject resource namespace
   * $3: subject resource local name
   * $4: predicate resource namespace
   * $5: predicate resource local name
   * $6: literal object
   * $7: switch [0,1]
   *	 0 = does not create reification if does not exist
   *	 1 = create new reification if does not exist
   * returns id of new resource that represents the statement reification
   */
  as
  'DECLARE    
     rval integer;
     stmt_subj integer;
     stmt_pred integer;
   BEGIN
     stmt_subj = rdf_res_get($2,$3,$7);
     stmt_pred = rdf_res_get($4,$5,$7);
     if ((stmt_obj > 0) and (stmt_pred > 0)) then
       rval = rdf_reif_get($1, stmt_subj, stmt_pred, $6, $7);
     end if;
     return coalesce(rval,-1);
   END;'
  language 'plpgsql';

create function rdf_reif_add_sas(integer,integer,integer,integer)
  returns integer
  /* $1: model id
   * $2: resource id of reified statement
   * $3: resource id of predicate of statement about reified statement
   * $4: resource id of object of statement about reified statement
   * returns id of new statement that represents the statement reification
   */
  as
  'DECLARE
     reif integer;
   BEGIN
     reif = rdf_reif_get($1,$2,1);
     return rdf_stmt_get($1,reif,$3,$4,1);
   END;'
  language 'plpgsql';

 
  
