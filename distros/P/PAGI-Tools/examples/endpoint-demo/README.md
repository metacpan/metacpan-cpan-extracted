# Endpoint Demo

Showcases all three PAGI endpoint types with middleware.

## Run

```bash
pagi-server -I lib --app examples/endpoint-demo/app.pl --port 5000
```

Visit http://localhost:5000/

## Features

### HTTP Endpoint (REST API)

```perl
package MessageAPI;
use parent 'PAGI::Endpoint::HTTP';

async sub get { ... }
async sub post { ... }
```

### WebSocket Endpoint (Echo)

```perl
package EchoWS;
use parent 'PAGI::Endpoint::WebSocket';

async sub on_connect { ... }
async sub on_receive { ... }
```

### SSE Endpoint (Notifications)

```perl
package MessageEvents;
use parent 'PAGI::Endpoint::SSE';

async sub on_connect { ... }
sub on_disconnect { ... }
```

### Middleware Examples

- `PAGI::Middleware::AccessLog` - Request logging
- Coderef middleware - Request timing, JSON validation

## Routes

- `GET/POST /api/messages` - REST API
- `WS /ws/echo` - WebSocket echo
- `SSE /events` - Live notifications
- `GET /*` - Static files
