# NAME

Test::Clear - Simply testing module

# SYNOPSIS

    use Test::Clear;
    use MyModule;
    my $module = MyModule->new;

    case "basically name:{name}" => { name => 'hixi' }, sub {
        my $dataset = @_;
        my $ret = $module->get_person($dataset->{name});
        is $ret, xxxxx;
    };
    # Subtest: basically name:hixi
    # ok 1

    subtest 'optional test case' => sub {
        my $guard = todo_scope 'not yet implementated';
        fail;
    };

# DESCRIPTION

Test::Clear is simply testing module.

# MODULE SUPPORTED

- Test::Pretty (>= 0.30)
- Test::Flatten (>= 0.10)

# METHODS

## case

### 

    case "basically name:{name}" => { name => 'hixi' }, sub {
        my $dataset = shift;
        my $ret = $module->get_person($dataset->{name});
        is $ret, xxxxx;
    };
    # Subtest: basically name:hixi

### 

    case 'request person data uri:{uri}' => sub {
        my $user_id = 1;
        my $uri     = 'http://example.com/person/' . $user_id;
        return {
            uri     => $uri,
            user_id => $user_id,
        }
    }, sub {
        my $dataset = shift;
        my $ret = $module->request($dataset->{uri});
        is $ret->{person}->{id}, $dataset->{user_id};
    };
     # Subtest: request person data uri:http://example.com/person/1



## todo\_scope

### 

    subtest 'optional case' => sub {
        my $guard = todo_scope 'not yet implementated';
        fail;
    };
    # Subtest: optional case
    not ok 1 # TODO not yet implementated

## todo\_scope

### 

    todo_note 'optional case';
    # not ok 1 - optional case # TODO

    todo_note 'optional case', 'not yet implementated';
    # not ok 1 - optional case # TODO not yet implementated

# LICENSE

Copyright (C) Hiroyoshi Houchi.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Hiroyoshi Houchi <git@hixi-hyi.com>
