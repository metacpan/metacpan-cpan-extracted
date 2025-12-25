# Endpoint Router Demo

Demonstrates PAGI::Endpoint::Router features:

- Lifespan hooks (on_startup/on_shutdown)
- HTTP routes with method handlers
- WebSocket with start_heartbeat()
- SSE with every() for periodic events
- Subrouters with stash inheritance
- Middleware as methods

## Running

```bash
cd examples/endpoint-router-demo
pagi-server --app app.pl --port 5000
```

Then open http://localhost:5000

## Endpoints

- `GET /` - Home page
- `GET /api/info` - API info with merged stash
- `GET /api/users` - List users
- `GET /api/users/:id` - Get user by ID
- `POST /api/users` - Create user
- `WS /ws/echo` - WebSocket echo
- `SSE /events/metrics` - Live metrics
