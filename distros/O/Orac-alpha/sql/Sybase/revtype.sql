/* Procedure copyright(c) 1995 by Alex Shnir */
:r database
go
:r dumpdb
go

if exists (select *
           from   sysobjects
           where  type = "P"
           and    name = "sp__revtype")
begin
    drop proc sp__revtype
end
go


create procedure sp__revtype (@type varchar(40), @dont_format char(1) = null)
as

declare @typeid int
declare @len1 int, @len2 int, @len3 int, @len4 int, @defs int, @rules int

begin
        select @typeid = usertype
                from systypes
                        where name = @type

        /*
        **  Time to give up -- @objname is not in sysobjects or systypes.
        */
        if @typeid is NULL
        begin
                /* 17461, "Object does not exist in this database." */
                raiserror 17461
                return  (1)
        end

        /*
        ** Print help about a data type
        */
        select @len1 = max(datalength(s.name)),
               @len2 = max(datalength(st.name)),
               @len3 = max(datalength(object_name(s.tdefault))),
               @len4 = max(datalength(object_name(s.domain)))
                from systypes s, systypes st
                    where s.usertype = @typeid
                        and s.type = st.type
                        and st.name not in ("sysname", "nchar", "nvarchar")
                        and st.usertype < 100

        if (@len1 > 15 or @len2 > 15 or @len3 > 15 or @len4 > 15)
	     select  'sp_addtype ' + s.name + ', ' + st.name +
               case
                when s.length = st.length and  (s.prec = 0 or s.prec is NULL) THEN ''
                when s.length >= 0 and  s.prec is not NULL THEN '(' +  rtrim(convert(char(5),s.prec))
                else '(' +  rtrim(convert(char(5),s.length))
               end +
               case
                when (s.scale = 0 or s.scale is NULL) and s.length = st.length  THEN ''
                when s.scale = 0 or s.scale is NULL THEN ')'
                else ', ' + rtrim(convert(char(5),s.scale)) + ')'
               end +
               case
                when s.allownulls = 1 then ', "null"'
                else ', "not null"'
                end
              from systypes s, systypes st
              where s.usertype = @typeid
                and s.type = st.type
                and st.name not in ("sysname", "nchar", "nvarchar")
                and st.usertype < 100
        else
             select  'sp_addtype ' + rtrim(convert(char(15), s.name)) + ', ' + rtrim(convert(char(15), st.name)) +
               case
                when s.length = st.length and  (s.prec = 0 or s.prec is NULL) THEN ''
                when s.length >= 0 and  s.prec is not NULL THEN '(' +  rtrim(convert(char(5),s.prec))
                else '(' +  rtrim(convert(char(5),s.length))
               end +
               case
                when (s.scale = 0 or s.scale is NULL) and s.length = st.length  THEN ''
                when s.scale = 0 or s.scale is NULL THEN ')'
                else ', ' + rtrim(convert(char(5),s.scale)) + ')'
               end +
               case
                when s.allownulls = 1 then ', "null"'
                else ', "not null"'
                end
                from systypes s, systypes st
                    where s.usertype = @typeid
                        and s.type = st.type
                        and st.name not in ("sysname", "nchar", "nvarchar")
                        and st.usertype < 100

	if (@len3 > 0)
           select 'sp_bindefault ' + object_name(s.tdefault) + ', ' + @type
              from systypes s, systypes st
              where s.usertype = @typeid
                and s.type = st.type
                and st.name not in ("sysname", "nchar", "nvarchar")
                and st.usertype < 100

	if (@len4 > 0)
            select 'sp_bindefault ' + object_name(s.domain) + ', '  +@type
              from systypes s, systypes st
              where s.usertype = @typeid
                and s.type = st.type
                and st.name not in ("sysname", "nchar", "nvarchar")
                and st.usertype < 100

        return (0)
end
go
grant exec on sp__revtype to public
go
