/* Copyright (c) 1995 by Edward M Barlow */

/************************************************************************\ 
 Procedure Name:	sp__datediff
								          
 Author:		ed barlow

 Description:		

\************************************************************************/ 
:r database
go
:r dumpdb
go

if exists (select *
           from   sysobjects
           where  type = "P"
           and    name = "sp__datediff")
begin
    drop proc sp__datediff
end
go
create proc sp__datediff(@startdate datetime,@scale char(1),@outp float output)
as

if	@scale='h'
begin
	select @outp= convert(float,datediff(mi,@startdate,getdate()))/60
end
else	if @scale='d'
begin
	select @outp= convert(float,datediff(hh,@startdate,getdate()))/24
end
else	if @scale='m'
begin
	select @outp= convert(float,datediff(ss,@startdate,getdate()))/60
end
else	if @scale='s'
begin
	select @outp= convert(float,datediff(ss,@startdate,getdate()))
end
return  0
go
grant execute on sp__datediff to public
go
