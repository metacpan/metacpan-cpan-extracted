# PostgreSQLHosting

High Availability, Load Balancing, and Replication for PostgreSQL using Hot Standby

## Install 

```
$ sudo apt-get install carton git
$ git clone git@github.com:ovntatar/PostgreSQLHosting.git
$ cd PostgreSQLHosting
$ carton install 
```

## Configuration

Edit `config.yml` according to your needs. 


> Please, use only alphanumeric characters and underscore to name the hosts

## Usage

### Deploy

```
PRIVATE_KEY=/path/to/private/key carton exec -- rex deploy
```

### List machines

```
PRIVATE_KEY=/path/to/private/key carton exec -- rex inventory
```


### Remove machines [!!!!]

PLEASE, BE CAREFUL. THIS COMMAND REMOVES ALL MACHINES

```
PRIVATE_KEY=/path/to/private/key carton exec -- rex wipe
```

