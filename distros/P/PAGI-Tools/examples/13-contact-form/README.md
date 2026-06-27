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

Pass per-request limits to `form_params` (the call that triggers multipart
parsing):

```perl
my $form = await $req->form_params(max_file_size => 5 * 1024 * 1024);
```

To change a default process-wide, `local`-ize the package variable in
`PAGI::Request::MultiPartHandler` (e.g. `$MAX_FILE_SIZE`).

## API

- `POST /submit` - Submit form with optional attachment
- `GET /*` - Static files from `public/`
