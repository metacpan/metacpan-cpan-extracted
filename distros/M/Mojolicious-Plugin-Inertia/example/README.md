# Mojolicious + Inertia.js + React Example

This example demonstrates a practical implementation of Inertia.js with Mojolicious and React using Vite.

## Setup

### Prerequisites

- Perl 5.10+ with Mojolicious
- Node.js 16+ and npm

### Installation

1. **Install Perl dependencies:**
```bash
cd example
cpanm --installdeps ..
```

2. **Install Node.js dependencies:**
```bash
npm install
```

3. **Build the frontend assets:**
```bash
npm run build
```

## Running the Application

### Development Mode

For development with hot reload:

```bash
morbo app.pl
```

Then visit http://localhost:3000

## Project Structure

```
example/
├── app.pl                 # Mojolicious application
├── dist/                  # Built frontend assets
│   ├── index.html        # HTML template with Inertia root
│   └── assets/           # Compiled JS/CSS
├── src/                  # React source code
│   ├── main.tsx          # Entry point
│   ├── Pages/            # Inertia page components
│   │   ├── Index.tsx
│   │   ├── Hello.tsx
│   │   ├── Dashboard.tsx
│   │   └── Todos/
│   │       ├── Index.tsx
│   │       └── Detail.tsx
│   └── components/       # Reusable components
├── package.json          # Node.js dependencies
└── vite.config.ts        # Vite configuration

```

