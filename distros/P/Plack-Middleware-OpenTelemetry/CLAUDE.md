# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development Commands

### Building and Testing
- **Run tests**: `prove -Ilib t/` or `perl -Ilib t/*.t`
- **Run single test**: `perl -Ilib t/basic.t`
- **Build distribution**: `dzil build` (requires Dist::Zilla)
- **Build trial release**: `dzil build --trial`

### Code Style and Quality
- Use `perltidy` for Perl code formatting
- Follow existing code style in `lib/Plack/Middleware/OpenTelemetry.pm`

## Project Architecture

This is a Perl distribution that provides OpenTelemetry tracing middleware for Plack applications.

### Core Components
- **Main module**: `lib/Plack/Middleware/OpenTelemetry.pm` - The primary middleware implementation
- **Test suite**: 
  - `t/basic.t` - Basic functionality tests
  - `t/context_propagation.t` - W3C trace context handling
  - `t/otel_integration.t` - OpenTelemetry SDK integration
- **Demo application**: `app.psgi` - Example Plack application for testing

### Key Dependencies
- Plack (>= 1.0050) - Core PSGI/Plack framework
- OpenTelemetry (>= 0.018) - OpenTelemetry Perl SDK
- OpenTelemetry::SDK (>= 0.020) - OpenTelemetry SDK implementation
- Feature::Compat::Try - Modern try/catch syntax
- Syntax::Keyword::Dynamically - Dynamic scope management

### Middleware Functionality
The middleware automatically:
1. Creates OpenTelemetry spans for HTTP requests
2. Extracts tracing context from incoming requests
3. Sets standard HTTP semantic attributes following OpenTelemetry conventions
4. Handles both synchronous and streaming responses
5. Records exceptions and sets appropriate span status

### Configuration Options
- `include_client_errors`: Boolean flag to mark 4xx HTTP status codes as errors (default: false)
- `resource_attributes`: Hash reference for custom resource attributes

### Testing Environment
Tests use the console exporter (`OTEL_TRACES_EXPORTER=console`) for development and debugging.

## Development Workflow

1. Make changes to the middleware code
2. Run `prove -Ilib t/` to verify all tests pass
3. Test with the demo app using `plackup app.psgi`
4. For releases, use `dzil build` to create distribution packages

## Environment Variables

The middleware respects standard OpenTelemetry environment variables:
- `OTEL_TRACES_EXPORTER` - Exporter type (console, otlp, etc.)
- `OTEL_SERVICE_NAME` - Service name for spans
- `OTEL_RESOURCE_ATTRIBUTES` - Additional resource attributes

## Usage Examples

### Basic Usage
```perl
builder {
    enable "Plack::Middleware::OpenTelemetry";
};
```

### With Custom Configuration
```perl
builder {
    enable "Plack::Middleware::OpenTelemetry",
        include_client_errors => 1,
        resource_attributes => {
            'service.version' => '1.0.0',
            'deployment.environment' => 'production',
        };
};
```

## Troubleshooting

- Use `OTEL_TRACES_EXPORTER=console` to see spans in console output
- Check that OpenTelemetry SDK is properly initialized
- Verify W3C trace context headers are being propagated correctly

## Dist::Zilla Configuration

The project uses Dist::Zilla for packaging and release management with:
- AutoVersion for automatic versioning
- Git integration for tagging and release management
- CPAN metadata generation
- Signature verification for releases