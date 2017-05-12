.timer off
.mode list
select load_extension('perlvtab.so');

create table students (student, subject, grade, primary key (student,subject));
insert into students values ("Fred", "Reading", "A");
insert into students values ("Fred", "Writing", "B-");
insert into students values ("Fred", "Arithmetic", "B");
insert into students values ("Mary", "Writing", "B");

create virtual table roster
     using perl ("SQLite::VirtualTable::Pivot", "students", "student", "subject", "grade" );

create table join_to_me ( student,subject,grade);
insert into join_to_me values ("Joe", "Reading", "C+");
insert into join_to_me values ("Fred", "Reading", "C+");
insert into join_to_me values ("Mary", "Reading", "A");

.header on
.echo on

select a.student, b.student,
    a.Reading,
    b.subject
 from roster a inner join join_to_me b on a.student=b.student;

create virtual table roster2
     using perl ("SQLite::VirtualTable::Pivot", "join_to_me", "student", "subject", "grade" );

select a.student, a.Writing from roster a inner join roster b
    on a.student=b.student;

select a.student, a.Writing, b.Reading from roster a inner join roster b
    on a.Reading=b.Reading;
