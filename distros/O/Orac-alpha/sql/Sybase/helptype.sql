/* Procedure copyright(c) 1995 by Edward M Barlow */
:r database
go
:r dumpdb
go

if exists (select *
           from   sysobjects
           where  type = "P"
           and    name = "sp__helptype")
begin
    drop proc sp__helptype
end
go

create procedure sp__helptype (@type varchar(40), @dont_format char(1) = null)
as

declare @typeid int
declare @len1 int, @len2 int, @len3 int, @len4 int

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
            select  Name = s.name,
                    Type = st.name,
                    Length = convert(char(5),s.length),
                Nulls = s.allownulls,
                Prec = s.prec,
                Scale = s.scale,
                Default_name = object_name(s.tdefault),
                Rule_name = object_name(s.domain),
                "Identity" = s.ident
                from systypes s, systypes st
                    where s.usertype = @typeid
                        and s.type = st.type
                        and st.name not in ("sysname", "nchar", "nvarchar")
                        and st.usertype < 100
        else
            select   Name = convert(char(15), s.name),
                     Type = convert(char(15), st.name),
                     Length = s.length,
                Prec = s.prec,
                Scale = s.scale,
                Nulls = s.allownulls,
                Default_name = convert(char(15), object_name(s.tdefault)),
                Rule_name = convert(char(15), object_name(s.domain)),
                "Identity" = s.ident
                from systypes s, systypes st
                    where s.usertype = @typeid
                        and s.type = st.type
                        and st.name not in ("sysname", "nchar", "nvarchar")
                        and st.usertype < 100

        return (0)
end
go
grant exec on sp__helptype to public
go
