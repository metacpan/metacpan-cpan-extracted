.timer off
.mode list
select load_extension('perlvtab.so');
.header on

drop table if exists students;
create table students (student, subject, grade, primary key (student,subject));
insert into students values ("Fred", "Reading", "A");
insert into students values ("Fred", "Writing", "B");
insert into students values ("Mary", "Writing", "B");
insert into students values ("Fred", "Arithmetic", "B");

drop table if exists roster;
create virtual table roster
     using perl ("SQLite::VirtualTable::Pivot", "students", "student", "subject", "grade" );

select * from roster;

select * from roster where reading="A" and writing="B";

select Reading from roster where student="Fred";

select Arithmetic from roster where student="Fred" and Reading="A";

select student from roster where Reading="A";

select student from roster where Reading is null;


