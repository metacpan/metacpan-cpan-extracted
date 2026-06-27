# PAGI::App::File Example

Static file server using PAGI::App::File.

## Run

```bash
pagi-server --app examples/app-01-file/app.pl --port 5000
```

## Features

- Static file serving from a root directory
- Index file resolution (`index.html`)
- MIME type detection
- ETag caching (304 Not Modified)
- Range requests for partial content
- Path traversal protection

## Test URLs

- http://localhost:5000/ - `index.html`
- http://localhost:5000/test.txt - Plain text
- http://localhost:5000/data.json - JSON
- http://localhost:5000/style.css - CSS
- http://localhost:5000/subdir/nested.txt - Nested file
