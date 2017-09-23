# Rails Assets Coverage

The purpose of this script is to find which assets are used by a Rails app.
I tried to not use any dependency in order to make it runnable on every UNIX machine without installing perl package manager.
This should be intended as a proof of concept for a future ruby gem:

### Demos

If you don't have cpanminus installed and you want to run some demos, please refer to the `demos` branch.

```
  # Ubuntu
  $ [VERBOSE=1|OUTPUT=1|] demo/rails_assets_ubuntu [RAILS_ROOT|.]
  # Windows: cmd prompt
  set VERBOSE=1
  echo %VERBOSE% # if you want to check
  set VERBOSE= #unset the variable with no spaces after = sign
  demo/rails_assets_win.exe [RAILS_ROOT]
```

### Usage

```
  $ [VERBOSE=1|OUTPUT=1|] perl -Ilib scripts/rails_assets.pl [RAILS_ROOT|.]
```
Options:
- `RAILS_ROOT` arg is the path to rails application you want to analyze.
- with `VERBOSE` env var the script will print on STDOUT the result of the parsing activity.
- with `OUTPUT` env var the script will generate an assets_status.yml report inside your `RAILS_ROOT`.

### Setup

#### UNIX

For a proper usage you should install `cpanminus` and `Module::Builder` perl module:

```
  $ sudo apt install cpanminus
  $ sudo cpanm -i Module::Builder
  $ perl Build.PL
  $ ./Build installdeps
  $ ./Build test
  $ ./Build install
```

Compile a demo:
```
  $ pp -o demo/rails_assets_ubuntu scripts/rails_assets.pl
```

#### Windows

- Download [Strawberry Perl](http://strawberryperl.com/)
- Open the perl command line *as administrato* and go to the directory where you cloned/downloaded this repo

```
  perl Build.PL
  Build installdeps
  Build test
  Build testcover
  Build install
```

Compile a demo:
```
  cpanm PAR::Packer # it takes a while ...
  Build install
  pp --verbose -o demo/rails_assets_win.exe scripts/rails_assets.pl
```

### Notes

This repo was born as a [gist](https://gist.github.com/mberlanda/ccabea23498d32f27f4591eb4d78a4be). I would keep it alive for discussions on this topic.

Any fork, star, issue or pull requests are welcome!
