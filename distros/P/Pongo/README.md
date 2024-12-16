# Pongo

**MongoDB Driver for Perl**

Pongo is a MongoDB driver for Perl, providing a simple interface for interacting with MongoDB databases. This package allows you to use MongoDB with Perl applications, supporting essential operations such as queries, insertions, and updates.

## Supported Versions

- **MongoDB Version**: 8.0.4
- **libmongoc Version**: 1.28.0

## Installation

### Linux

For Ubuntu/Debian-based systems, install the required dependencies:

```bash
sudo apt-get install libmongoc-1.0-0 libbson-1.0-0 libmongoc-dev libbson-dev
```

### macOS

For macOS, use Homebrew to install the necessary MongoDB C driver dependencies:

```zsh
brew install mongo-c-driver
```

### Install the Pongo Package

1. Clone the repository:

   ```bash
   git clone https://github.com/h4ck3r-04/Pongo.git
   cd Pongo
   ```

2. Build and install the package:

   ```bash
   perl Makefile.PL
   make
   sudo make install
   ```

3. To clean the build:

   ```bash
   make clean
   ```

## License

This project is licensed under the [GPL-3.0 License](LICENSE).

## Copyright

Copyright (c) 2024, Rudraditya Thakur. All rights reserved.
