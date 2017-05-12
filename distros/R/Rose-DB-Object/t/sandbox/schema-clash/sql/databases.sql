drop database if exists alpha;
drop database if exists beta;

create database alpha;
create database beta;

grant all privileges on alpha.* to 'alpha'@'localhost'
    identified by 'alphapass'; 
grant all privileges on beta.*  to 'beta'@'localhost'
    identified by 'betapass'; 
flush privileges;
