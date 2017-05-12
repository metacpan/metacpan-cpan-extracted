QBit::Application::Model::DB::mysql::Users
=====

DB model for mysql table structure for model users in QBit application.

## Usage

### Install:

```
apt-get install libqbit-application-model-db-mysql-users-perl
```

### Require:

```
use QBit::Application::Model::DB::mysql::Users accessor => db; #in Application.pm
```

or

```
package Application::Model::DB; #main DB model

use qbit;

use base qw(
  QBit::Application::Model::DB::mysql::Users
  );

TRUE;
```

### Create sql

```
$app->db->create_sql(qw(users users_extra_fields));

```
