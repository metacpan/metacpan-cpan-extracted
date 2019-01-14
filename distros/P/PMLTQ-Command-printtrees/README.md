# pmltq-command-printtrees

This perl module adds to `pmltq` (from [PMLTQ::Commands](https://github.com/ufal/pmltq-commands)) subcommand `pmltq printtrees`. Module depends on btred which is part of [TrEd](https://ufal.mff.cuni.cz/tred/).

## Running
You can run tree generation with this command `pmltq printtrees`. This values are used in default:

```
printtrees:
  btred_rc: File::Spec->catdir(shared_dir(),'btred.rc'), # btred.rc distributed within PMLTQ::Command::printtrees module is used
  tree_dir: 'svg',
  btred: $ENV{BTRED} || which('btred'),
  extensions: $extensions, # list of all TrEd's activated extensions is used
  parallel:
    job_size: 50,
    forks: 8
```


X server is needed for generating svg trees. So if you are running it throw ssh without X you can use virtual framme buffer

```
xvfb-run pmltq printtrees
```


## Instalation

If you want to run tests during installation you should install btred and add btred path to `BTRED_PATH` environment variable.