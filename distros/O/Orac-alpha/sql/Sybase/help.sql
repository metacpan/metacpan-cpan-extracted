/* Procedure copyright(c) 1995 by Edward M Barlow */

:r database
go
:r dumpdb
go

if exists (select *
           from   sysobjects
           where  type = "P"
           and    name = "sp__help")
begin
    drop proc sp__help
end
go

create procedure sp__help( @object varchar(92)=NULL ,
	@dont_format char(1) = null
	)
as
begin

   declare @msg char(128)
   set nocount on
   
   if @object is not null
   begin
		/* Not a table view or system proc */
	   if not exists ( select * from sysobjects where name=@object 
						and type in ('U','V','S') )
		begin
			execute sp_help @object
			return
		end

		select  
			  Name = o.name,
			  Owner = convert(char(17),user_name(uid)),
			  Object_type = convert(char(22), m.description + x.name)
		from sysobjects o, master.dbo.spt_values  v,
			  master.dbo.spt_values x, master.dbo.sysmessages m
		where o.sysstat & 2055 = v.number
			  and v.type = "O"
			  and v.msgnum = m.error
			  and m.error between 17100 and 17109
			  and o.name = @object
			  and x.type = "R"
			  and o.userstat &  -32768 = x.number
		order by Object_type desc, Name asc

	   if exists ( select * from sysobjects 
						where name=@object 
						and type in ('U','V','S') )
	   begin
			/* Trigger Info */
			exec sp__trigger @object

			/* Column Information */
			exec sp__helpcolumn @object

			/* Basic Index Information (why not) */
			print ""
			print "**** Index Information ****"
			exec sp__helpindex @object
		end
   end
   else
   begin
		select  
			  Name = convert(char(20),o.name),
			  Owner = convert(char(20),user_name(uid)),
			  Object_type = convert(char(22), v.name)
		from sysobjects o, master.dbo.spt_values  v
		where o.sysstat & 2055 = v.number
			  and v.type = "O"
			  and o.type!='S'
		order by Object_type desc, Name asc
   end
end
go

grant execute on sp__help to public
go
