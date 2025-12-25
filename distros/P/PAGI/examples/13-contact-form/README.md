# Contact Form Example

Demonstrates PAGI::Request form handling and file uploads.

## Run

```bash
pagi-server --app examples/13-contact-form/app.pl --port 5000
```

Visit http://localhost:5000/

## Features

- Form parsing with validation
- File upload handling with type/size validation
- MIME type whitelist (PDF, images, text)
- JSON API responses
- Static file serving from `public/`

## Upload Limits

```perl
PAGI::Request->configure(
    max_file_size   => 5 * 1024 * 1024,  # 5MB per file upload
    spool_threshold => 64 * 1024,         # Spool to disk above 64KB
);
```

## API

- `POST /submit` - Submit form with optional attachment
- `GET /*` - Static files from `public/`
