QBit::Application::Model::DB::mysql::Authorization
=====

DB model for mysql table structure for model Authorization in QBit application.

## Usage

### Install:

```
apt-get install libqbit-application-model-db-mysql-authorization-perl
```

### Require:

```
use QBit::Application::Model::DB::mysql::Authorization accessor => db; #in Application.pm
```

or

```
package Application::Model::DB; #main DB model

use qbit;

use base qw(
  QBit::Application::Model::DB::mysql::Authorization
  );

TRUE;
```

### Create sql

```
$app->db->create_sql(qw(authorization));

```
