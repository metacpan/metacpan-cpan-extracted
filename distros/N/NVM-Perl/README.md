# nvm-pl

A fast, lightweight Perl-based Node.js version manager. Install, switch, and manage multiple Node.js versions with ease.

![Tests](https://github.com/jkhall81/nvm-pl/actions/workflows/test.yml/badge.svg)
![Perl](https://img.shields.io/badge/Perl-5.38+-blue.svg)
![Platform](https://img.shields.io/badge/Platform-Linux%20%7C%20macOS%20%7C%20Windows-green.svg)

## Features

- **Fast** - Written in Perl
- **Cross-platform** - Works on Linux, macOS, and Windows
- **Multi-shell support** - Bash, Zsh, Cmd, PowerShell
- **Seamless switching** - Auto-updates shell configuration
- **Smart caching** - Avoids re-downloading Node.js versions
- **Well-tested** - 72+ tests with CI/CD on 3 platforms

## Quick Start

### Installation

```bash
# Install from CPAN
sudo cpanm JHALL/NVM-Perl-0.1.1.tar.gz

# Or clone and install manually
git clone https://github.com/jkhall81/nvm-pl.git
cd nvm-pl
cpanm --installdeps .
sudo make install
```

### Basic Usage

```bash
# Install a Node.js version
nvm-pl install 25.1.0

# Use a specific version
nvm-pl use 25.1.0

# List installed versions
nvm-pl ls

# List available remote versions
nvm-pl ls-remote

# Show current version
nvm-pl current

# Uninstall a version
nvm-pl uninstall 25.1.0
```

## Supported Shells

- **Bash** - Updates `~/.bashrc`
- **Zsh** - Updates `~/.zshrc` (macOS default)
- **Cmd** - Windows Command Prompt
- **PowerShell** - Windows PowerShell

## How It Works

`nvm-pl` manages Node.js versions in `~/.nvm-pl/install/`:

```
~/.nvm-pl/install/
├── downloads/     # Cached Node.js tarballs
├── versions/      # Installed Node.js versions
│   ├── v25.1.0/
│   ├── v24.11.0/
│   └── current -> v25.1.0/  # Symlink/junction to active version
└── node_index_cache.json    # Cached version list
```

## Commands

| Command                      | Description                                |
| ---------------------------- | ------------------------------------------ |
| `nvm-pl install <version>`   | Install a Node.js version                  |
| `nvm-pl use <version>`       | Switch to a version (updates shell config) |
| `nvm-pl ls`                  | List installed versions                    |
| `nvm-pl ls-remote`           | List available remote versions             |
| `nvm-pl current`             | Show active version                        |
| `nvm-pl uninstall <version>` | Remove a version                           |
| `nvm-pl --help`              | Show help message                          |
| `nvm-pl --version`           | Show version                               |

## Examples

```bash
# Install the latest LTS version
nvm-pl install 24.11.0
nvm-pl use 24.11.0

# Install multiple versions
nvm-pl install 25.1.0
nvm-pl install 24.11.0
nvm-pl install 23.10.0

# Switch between versions
nvm-pl use 25.1.0
node --version  # v25.1.0

nvm-pl use 24.11.0
node --version  # v24.11.0

# See what's installed
nvm-pl ls
# [nvm-pl] Installed versions:
#  v24.11.0
#  v25.1.0
```

## Migration from Other Version Managers

### From nvm

```bash
# Remove nvm
rm -rf ~/.nvm

# Remove nvm lines from ~/.bashrc/~/.zshrc
# Install and use nvm-pl as shown above
```

### From system Node.js

```bash
# Remove system Node.js (Ubuntu/Debian)
sudo apt remove nodejs npm

# Use nvm-pl exclusively
nvm-pl install 25.1.0
nvm-pl use 25.1.0
```

## Configuration

Create `~/.nvmplrc` for custom settings:

```ini
install_dir = /custom/path/.nvm-pl
mirror_url = https://nodejs.org/dist
cache_ttl = 86400
auto_use = 1
color_output = 1
```

## Development

```bash
# Clone the repository
git clone https://github.com/jkhall81/nvm-pl.git
cd nvm-pl

# Install dependencies
cpanm --installdeps .

# Run tests
prove -lv t/

# Build distribution
perl Makefile.PL
make
make test
make dist
```

## Why nvm-pl?

- **Lightweight** - No heavy JavaScript toolchain required
- **Fast** - Perl is optimized for system utilities
- **Simple** - Clean, readable codebase
- **Reliable** - Comprehensive test suite
- **Cross-platform** - True multi-OS support

## License

MIT License - see [LICENSE](LICENSE) file for details.

## Contributing

Contributions welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create a feature branch
3. Add tests for your changes
4. Ensure all tests pass
5. Submit a pull request

Happy Node.js version managing!
