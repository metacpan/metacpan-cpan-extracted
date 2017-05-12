QBit::Validator
=====

Model for check options in QBit application.

## Usage

### Install:

```
apt-get install libqbit-validator-perl
```

### Require:

```
use QBit::Validator; #in package
```

### Methods:

  - new - create object QBit::Validator and check data using template

```
my $data = {
    hello => 'hi, qbit-validator'
};

my $qv = QBit::Validator->new(
    data => $data,
    template => {
        type => 'hash',
        fields => {
            hello => {
                max_len => 5,
            },
        },
    },
);
```

  - template - get or set template

```
my $template = $qv->template;

$qv->template($template);
```

  - has_errors - return boolean result (TRUE if an error has occurred or FALSE)

```
if ($qv->has_errors) {
    ...
}
```

  - data - return data

```
$self->db->table->edit($qv->data) unless $qv->has_errors;
```

  - get_wrong_fields - return list name of fields with error

```
if ($qv->has_errors) {
    my @fields = $qv->get_wrong_fields;

    ldump(\@fields); # ['hello']
    # [''] - error in root
}
```

  - get_fields_with_error - return list fields with error

```
if ($qv->has_errors) {
    my @fields = $qv->get_fields_with_error;

    ldump(\@fields);

    # [
    #     {
    #         msgs => ['Error'],
    #         path => ['hello']
    #     }
    # ]
    #
    # path => [''] - error in root
}
```

  - get_error - return error by path

```
if ($qv->has_errors) {
    my $error = $qv->get_error('hello'); # or ['hello']

    print $error; # 'Error'
}
```

  - get_all_errors - return all errors join "\n"

```
if ($qv->has_errors) {
    my $errors = $qv->get_all_errors();

    print $errors; # 'Error'
}
```

  - throw_exception - throw Exception::Validator with error message from get_all_errors

```
$qv->throw_exception if $qv->has_errors;
```

### Options:

  - data (checking data)
  - template (template for check)
  - pre_run (function is executed before checking)
  - app (model using in check)
  - throw (boolean type, throw exception if an error has occurred)

### Default types

  - #### scalar (string/number)

    - optional
    - eq
    - regexp
    - min
    - max
    - len_min
    - len
    - len_max
    - in

    For more information see tests

  - #### array (ref array)

    - optional
    - size_min
    - size
    - size_max
    - all
    - contents

    For more information see tests

  - #### hash (ref hash)

    - optional
    - deps
    - fields
    - extra
    - one_of
    - any_of

    For more information see tests
