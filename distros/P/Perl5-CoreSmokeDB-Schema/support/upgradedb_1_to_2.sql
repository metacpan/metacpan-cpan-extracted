begin;
    alter table report
     add column nonfatal_msgs bytea;

    update tsgateway_config
       set value = '2'
     where name  = 'dbversion'
       and value = '1'
           ;
commit;
