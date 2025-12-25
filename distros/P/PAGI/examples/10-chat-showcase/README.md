# Multi-User Chat Showcase

A comprehensive demo application showcasing PAGI's capabilities through a real-time multi-user chat system.

## Features Demonstrated

### PAGI Protocol Types
- **WebSocket** (`/ws/chat`) - Real-time bidirectional messaging
- **HTTP** - Static file serving and REST API endpoints
- **SSE** (`/events`) - Server-Sent Events for system notifications
- **Lifespan** - Application startup/shutdown lifecycle

### Chat Features
- Multiple chat rooms (create, join, leave)
- Real-time message broadcasting
- Typing indicators
- Private messaging (`/pm user message`)
- User presence tracking
- Message history (last 100 per room)
- Chat commands (`/help`, `/nick`, `/rooms`, `/users`, `/me`)

## Running the Application

```bash
# From the PAGI root directory
perl -Ilib -Iexamples/10-chat-showcase/lib bin/pagi-server \
    --app examples/10-chat-showcase/app.pl \
    --port 5000

# Then open http://localhost:5000 in your browser
```

## Architecture

```
examples/10-chat-showcase/
├── app.pl                    # Main PAGI application (routing + middleware)
├── lib/ChatApp/
│   ├── State.pm              # Shared state management (in-memory)
│   ├── HTTP.pm               # HTTP handler (static files + API)
│   ├── WebSocket.pm          # WebSocket chat handler
│   └── SSE.pm                # SSE system events
└── public/
    ├── index.html            # Chat interface
    ├── css/style.css         # Styles (light/dark themes)
    └── js/app.js             # Frontend JavaScript
```

## API Endpoints

### HTTP
- `GET /` - Chat frontend
- `GET /api/rooms` - List rooms with user counts
- `GET /api/room/:name/history` - Message history
- `GET /api/room/:name/users` - Users in room
- `GET /api/stats` - Server statistics

### WebSocket (`/ws/chat?name=Username`)
JSON message protocol for real-time chat.

### SSE (`/events`)
System-wide event stream (user connects, stats updates).

## Chat Commands

Type these in the chat input:

| Command | Description |
|---------|-------------|
| `/help` | Show available commands |
| `/rooms` | List all rooms |
| `/users` | List users in current room |
| `/join <room>` | Join or create a room |
| `/leave` | Leave current room |
| `/pm <user> <msg>` | Send private message |
| `/nick <name>` | Change your nickname |
| `/me <action>` | Send action message |

## WebSocket Message Protocol

### Client to Server
```json
{ "type": "message", "room": "general", "text": "Hello!" }
{ "type": "join", "room": "random" }
{ "type": "leave", "room": "random" }
{ "type": "typing", "room": "general", "typing": true }
{ "type": "pm", "to": "username", "text": "Hi!" }
{ "type": "set_nick", "name": "NewName" }
```

### Server to Client
```json
{ "type": "connected", "user_id": "...", "name": "...", "rooms": [...] }
{ "type": "message", "room": "...", "from": "...", "text": "...", "ts": ... }
{ "type": "user_joined", "room": "...", "user": "...", "users": [...] }
{ "type": "user_left", "room": "...", "user": "...", "users": [...] }
{ "type": "typing", "room": "...", "user": "...", "typing": true }
{ "type": "pm", "from": "...", "text": "...", "ts": ... }
{ "type": "error", "message": "..." }
```

## Frontend Features

- Responsive design (mobile-friendly)
- Dark/light theme toggle (persisted)
- Auto-reconnecting WebSocket
- Connection status indicator
- Keyboard-friendly navigation
- Real-time stats via SSE
