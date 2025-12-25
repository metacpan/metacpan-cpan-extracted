# UTF-8 Round-Trip Test

Demonstrates UTF-8 handling across all PAGI input vectors.

## Run

```bash
pagi-server --app examples/12-utf8/app.pl --port 5000
```

Visit http://localhost:5000/

## Tests

1. **Path Test** - `/echo/{utf8_string}`: `$scope->{path}` is decoded, `$scope->{raw_path}` is bytes
2. **Query String Test** - `?text={utf8_string}`: Percent-encoded bytes
3. **POST Body Test** - Form submission: Application decodes percent-encoded body
4. **Response Test** - UTF-8 literals encoded for wire, Content-Length in bytes

## Key Points

- `$scope->{path}` is already UTF-8 decoded
- Query strings and bodies arrive as bytes - app must decode
- Response bodies must be `encode_utf8()` before sending
- `Content-Length` must be byte length, not character count
