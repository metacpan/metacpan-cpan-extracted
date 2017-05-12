QBit::Application::Model::DBManager::Users
=====

Model for work with users in QBit application.

## Usage

### Install:

```
apt-get install libqbit-application-model-dbmanager-users-perl
```

### Require:

```
use QBit::Application::Model::DBManager::Users accessor => users; #in Application.pm
```

### Default fields:

  - id (INT)
  - create_dt (DATETIME)
  - login (VARCHAR 255)
  - mail (VARCHAR 255)
  - name (VARCHAR 255)
  - midname (VARCHAR 255)
  - surname (VARCHAR 255)
  - extra_fields (perl hash)

All extra fields contained in field "extra_fields"

### Methods:

  - add

```
my $id = $app->users->add(
    login => 'Login', #required
    mail  => 'mail@ya.ru',
    name  => 'Name',
    extra_fields => {
        phone   => '123-456-78-90',
        address => 'address 23'
    },
);
```

  - edit

```
$app->users->edit($id,
    mail => 'mail@yandex.ru',
    extra_fields => {
        phone   => '+7 (123) 456-78-90',
        address => undef, # delete extra field
    },
    # extra_fields => undef - delete all extra fields for this user
);
```

  - check_user - empty sub, use it for options validation

### Redefine:

```
>$ nano Application::Model::Users;

package Application::Model::Users;

use qbit;

use QBit::Base qw(QBit::Application::Model::DBManager::Users); #QBit::Application::Model::Multistate

__PACKAGE__->model_accessors(db => 'QBit::Application::Model::DB::Users');

__PACKAGE__->model_fields(
    full_name => {
        label      => d_gettext('Full name'),
        depends_on => [qw(name midname surname)],
        get        => sub {
            return join(' ', grep {$_} map {$_[1]->{$_}} qw(surname name midname));
          }
    },
    # access for field from extra fields
    phone => {
        label      => d_gettext('Phone'),
        depends_on => ['extra_fields'],
        get        => sub {
            $_[1]->{'extra_fields'}{'phone'}[0]; # All data to save in array
          }
    },
);

__PACKAGE__->model_filter(
    db_accessor => 'db',
    fields      => {
        # filter field for extra fields
        phone => {
            type     => 'extra_fields',
            field    => 'id',
            fk_field => 'user_id',
            table    => 'users_extra_fields'
        },
    },
);

TRUE;
```