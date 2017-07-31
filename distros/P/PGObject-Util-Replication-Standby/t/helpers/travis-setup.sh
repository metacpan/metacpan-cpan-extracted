#!/bin/bash

PGVERSION=9.6

# base permissions setup
sudo chmod 755 /var
sudo chmod 755 /var/lib
sudo chmod 755 /var/lib/postgresql
sudo chmod 777 /var/lib/postgresql/$PGVERSION
sudo chmod 777 /var/run/postgresql/


# Main cluster set to clean slate (main2 on 5433)
sudo service postgresql stop
sudo pg_lsclusters 
sudo pg_createcluster $PGVERSION main2 # PORT 5433
sudo sh -c "cat t/helpers/config/main.conf >> /etc/postgresql/$PGVERSION/main2/postgresql.conf"
sudo pg_ctlcluster $PGVERSION main2 start
sudo -u postgres createuser -s -p 5433 travis &>/dev/null

# create replica
sudo service postgresql stop
sudo pg_createcluster -u travis $PGVERSION replica # PORT 5434
sudo sh -c "cat t/helpers/config/main.conf >> /etc/postgresql/$PGVERSION/replica/postgresql.conf"
sudo rm -rf ~postgres/$PGVERSION/replica 
sudo cp -r ~postgres/$PGVERSION/main2 ~postgres/$PGVERSION/replica 
sudo chown -R travis ~postgres/$PGVERSION/replica
sudo cp t/helpers/config/recovery.conf ~postgres/$PGVERSION/replica
sudo sh -c "cat t/helpers/config/replica.conf >> /etc/postgresql/$PGVERSION/replica/postgresql.conf"
sudo sh -c "echo 'local replication	travis	trust' >> /etc/postgresql/$PGVERSION/main2/pg_hba.conf"
sudo service postgresql start $PGVERSION

#diagnostics and more
echo 'sleeping for 3 sec'
sudo pg_lsclusters;
sleep 3
sudo ls /var/log/postgresql/
sudo cat /etc/postgresql/$PGVERSION/main2/postgresql.conf
sudo cat /var/log/postgresql/postgresql-9.6-replica.log
echo 'MAIN LOG'
sudo cat /var/log/postgresql/postgresql-9.6-main2.log
