# Mojolicious::Command::coverage

![https://metacpan.org/pod/Mojolicious::Command::coverage](https://img.shields.io/cpan/v/Mojolicious-Command-coverage)

Start you Mojo app in coverage mode. In short this command does the following:

```text

./myapp.pl coverage [application arguments]
# Is translated to
perl -I $INC[0] ... - I $INC[N] -MDevel::Cover=$coverageConfig -MDevel::Deanonymize=$deanonConfig myapp.pl [application arguments]

```

# SYNOPSIS

```text
Usage: APPLICATION coverage [OPTIONS] [APPLICATION_OPTIONS]

./myapp.pl coverage [application arguments]

Options:
-h, --help                Shows this help
-c, --cover-args <args>   Options for Devel::Cover
-d, --deanon-args <args>  Options for Devel::Deanonymize (set to 0 to disable Devel::Deanonymize)

Application Options
- All parameters not matching [OPTIONS] are forwarded to the mojo application
```

# USAGE

Runtime configuration for both modules are either passed through the command-line arguments or by specifying
`has` sections in your application:

```perl5
has coverageConfig => sub {
    return "-ignore,t/,+ignore,prove,+ignore,thirdparty/,-coverage,statement,branch,condition,path,subroutine";
};

has deanonymizeConfig => sub {
    return "<Include-pattern>"
};
```

If both are present, command-line args are preferred. If none of them are present, we fall-back to these default values:

- **Devel::Cover**`-ignore,t/,-coverage,statement,branch,condition,path,subroutine`
- **Devel::Deanonymize** `ref $self->app` ( -> Resolves to your application name)

# EXAMPLES

```shell
# EXAMPLE (with `has` sections or default config)
./myapp.pl coverage daemon --listen "http://*:8888"

# EXAMPLE (with args)
./myapp.pl coverage -d MyPattern* daemon --listen "http://*:8888"
```



