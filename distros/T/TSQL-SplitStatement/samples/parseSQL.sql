
/* comment 1 */
begin tran
begin try -- try
select case when 1=1 then 3 else 3 end
begin try
if 1=1
    select 1
else    if 2=2 begin
        print 1
    end
else    begin
    select 1
    end
end try
/* 
***
*/

select 1 as a
from ( select 1 as a union all select 2 ) x
select 1 as a
from ( select 1 as a except select 2 ) x

label:
label2:

begin catch
begin 
select 1
end
end catch

commit
end try
begin catch
rollback
end catch


begin transaction

commit

