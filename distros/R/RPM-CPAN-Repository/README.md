# RPM::CPAN::Repository

Manages the MediaAlpha public RPM repository on Amazon Linux 2023 (x86_64).

## Requirements

- Amazon Linux 2023, x86_64
- Perl 5.16+
- `Config::Tiny` CPAN module

## Install

```bash
perl Build.PL
./Build
sudo ./Build install
```

## Usage

```
sudo manage-mediaalpha-public-repo.pl [--add|--remove|--check] [--help]

  --add      Install the MediaAlpha public RPM repository
  --remove   Remove the MediaAlpha public RPM repository
  --check    Verify the repository is correctly configured
  --help     Show help
```

## Bugs

Report issues at https://github.com/MediaAlpha/perl-rpm-cpan-repository/issues
