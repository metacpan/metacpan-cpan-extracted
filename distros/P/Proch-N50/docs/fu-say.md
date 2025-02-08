# NAME

fu-say - SeqFu testing tool.

# SYNOPSIS

    fu-say [options]
    fu-say --version
    fu-say -s "Hello world"
    fu-say --fail

# DESCRIPTION

Testing tool. Check FASTX::Reader version and availability of SeqFu binary to Proch::Seqfu.

# OPTIONS

- **-s**, **--string** STRING

    Text to output (default: "OK")

- **-f**, **--fail**

    Exit with code 1 (failure)

- **-v**, **--version**

    Print version information on FASTX::Reader \[to check what library is active\]

- **-h**, **--help**

    Show this help message

# ENVIRONMENT

- **DEBUG**

    If set, prints FASTX::Reader version to STDERR

# EXIT STATUS

Returns 0 unless --fail is specified, then returns 1

# EXAMPLES

Print custom message:
  fu-say -s "Process completed"

Simulate failure:
  fu-say --fail -s "Error occurred"
