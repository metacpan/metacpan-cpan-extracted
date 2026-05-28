# Skills Parameter Schema System

This guide explains the parameter schema system for SignalWire AI Agents SDK skills, which enables GUI configuration tools and programmatic skill discovery.

## Overview

The parameter schema system allows skills to declare their configurable parameters with metadata including types, descriptions, default values, and security hints. This enables:

- **GUI Configuration Tools** - Automatically generate configuration forms
- **API Documentation** - Document all available parameters
- **Validation** - Type checking and constraint validation
- **Security** - Mark sensitive parameters as hidden
- **Environment Variables** - Indicate which parameters can be sourced from environment

## Using the Schema System

### Getting All Skills Schema

Use the `list_skills_with_params()` function to get a complete schema of all available skills:

```python
from signalwire_agents import list_skills_with_params

# Get complete schema for all skills
schema = list_skills_with_params()

# Example output structure:
{
    "web_search": {
        "name": "web_search",
        "description": "Search the web for information using Google Custom Search API",
        "version": "1.0.0",
        "supports_multiple_instances": True,
        "required_packages": ["bs4", "requests"],
        "required_env_vars": [],
        "parameters": {
            "api_key": {
                "type": "string",
                "description": "Google Custom Search API key",
                "required": True,
                "hidden": True,
                "env_var": "GOOGLE_SEARCH_API_KEY"
            },
            "search_engine_id": {
                "type": "string",
                "description": "Google Custom Search Engine ID",
                "required": True,
                "hidden": True,
                "env_var": "GOOGLE_SEARCH_ENGINE_ID"
            },
            "num_results": {
                "type": "integer",
                "description": "Default number of search results to return",
                "default": 1,
                "required": False,
                "min": 1,
                "max": 10
            },
            ...
        }
    },
    "datetime": {
        "name": "datetime",
        "description": "Get current date, time, and timezone information",
        "version": "1.0.0",
        "supports_multiple_instances": False,
        "required_packages": ["pytz"],
        "required_env_vars": [],
        "parameters": {
            "swaig_fields": {
                "type": "object",
                "description": "Additional SWAIG function metadata to merge into tool definitions",
                "default": {},
                "required": False
            }
        }
    },
    ...
}
```

### Using Schema for GUI Configuration

Here's an example of how to use the schema to generate a configuration form:

```python
import json
from signalwire_agents import list_skills_with_params, AgentBase

# Get skills schema
schema = list_skills_with_params()

# Example: Generate HTML form for web_search skill
web_search_schema = schema['web_search']

def generate_form_field(param_name, param_info):
    """Generate HTML form field based on parameter schema"""
    field_html = f'<div class="form-group">\n'
    field_html += f'  <label for="{param_name}">{param_info["description"]}</label>\n'
    
    # Mark required fields
    required = "required" if param_info.get("required", False) else ""
    
    # Hide sensitive fields
    input_type = "password" if param_info.get("hidden", False) else "text"
    
    # Handle different types
    if param_info["type"] == "string":
        default = param_info.get("default", "")
        field_html += f'  <input type="{input_type}" id="{param_name}" name="{param_name}" '
        field_html += f'value="{default}" {required}>\n'
    
    elif param_info["type"] == "integer":
        default = param_info.get("default", 0)
        min_val = f'min="{param_info["min"]}"' if "min" in param_info else ""
        max_val = f'max="{param_info["max"]}"' if "max" in param_info else ""
        field_html += f'  <input type="number" id="{param_name}" name="{param_name}" '
        field_html += f'value="{default}" {min_val} {max_val} {required}>\n'
    
    elif param_info["type"] == "boolean":
        default = param_info.get("default", False)
        checked = "checked" if default else ""
        field_html += f'  <input type="checkbox" id="{param_name}" name="{param_name}" {checked}>\n'
    
    # Show environment variable hint
    if "env_var" in param_info:
        field_html += f'  <small>Can also be set via {param_info["env_var"]} environment variable</small>\n'
    
    field_html += '</div>\n'
    return field_html

# Generate form fields for web_search skill
print("<form>")
for param_name, param_info in web_search_schema["parameters"].items():
    print(generate_form_field(param_name, param_info))
print("</form>")
```

### Programmatic Skill Configuration

Use the schema to validate and configure skills programmatically:

```python
from signalwire_agents import AgentBase, list_skills_with_params

class MyAgent(AgentBase):
    def __init__(self):
        super().__init__(name="my-agent")
        
        # Get schema to validate configuration
        schema = list_skills_with_params()
        
        # Configure web_search skill with validation
        web_search_params = {
            "api_key": "your-api-key",
            "search_engine_id": "your-engine-id",
            "num_results": 3,
            "max_content_length": 3000
        }
        
        # Validate required parameters
        web_search_schema = schema["web_search"]["parameters"]
        for param, info in web_search_schema.items():
            if info.get("required", False) and param not in web_search_params:
                raise ValueError(f"Missing required parameter: {param}")
        
        # Add skill with validated parameters
        self.add_skill("web_search", web_search_params)
```

## Parameter Schema Reference

Each parameter in the schema can have the following properties:

| Property | Type | Description |
|----------|------|-------------|
| `type` | string | Parameter type: "string", "integer", "number", "boolean", "object", "array" |
| `description` | string | Human-readable description of the parameter |
| `default` | any | Default value if not provided |
| `required` | boolean | Whether the parameter is required (default: false) |
| `hidden` | boolean | Whether to hide this field in UIs (for secrets/API keys) |
| `env_var` | string | Environment variable that can provide this value |
| `enum` | array | List of allowed values (for string types) |
| `min` | number | Minimum value (for numeric types) |
| `max` | number | Maximum value (for numeric types) |

## Implementing Parameter Schema in Skills

To add parameter schema support to a skill, override the `get_parameter_schema()` class method:

```python
from signalwire_agents.core.skill_base import SkillBase
from typing import Dict, Any

class MyCustomSkill(SkillBase):
    SKILL_NAME = "my_custom_skill"
    SKILL_DESCRIPTION = "My custom skill"
    SKILL_VERSION = "1.0.0"
    REQUIRED_PACKAGES = []
    REQUIRED_ENV_VARS = []
    
    @classmethod
    def get_parameter_schema(cls) -> Dict[str, Dict[str, Any]]:
        """Get parameter schema for this skill"""
        # Get base schema from parent (includes common parameters)
        schema = super().get_parameter_schema()
        
        # Add skill-specific parameters
        schema.update({
            "api_endpoint": {
                "type": "string",
                "description": "API endpoint URL",
                "required": True,
                "default": "https://api.example.com"
            },
            "api_key": {
                "type": "string",
                "description": "API authentication key",
                "required": True,
                "hidden": True,  # Mark as sensitive
                "env_var": "MY_API_KEY"  # Can be set via environment
            },
            "timeout": {
                "type": "integer",
                "description": "Request timeout in seconds",
                "default": 30,
                "required": False,
                "min": 1,
                "max": 300
            },
            "retry_count": {
                "type": "integer",
                "description": "Number of retries on failure",
                "default": 3,
                "required": False,
                "min": 0,
                "max": 10
            },
            "output_format": {
                "type": "string",
                "description": "Output format for results",
                "default": "json",
                "required": False,
                "enum": ["json", "xml", "text"]  # Allowed values
            },
            "enable_cache": {
                "type": "boolean",
                "description": "Enable response caching",
                "default": True,
                "required": False
            }
        })
        
        return schema
    
    def setup(self) -> bool:
        """Setup the skill using parameters"""
        # Access parameters via self.params
        self.api_endpoint = self.params.get('api_endpoint')
        self.api_key = self.params.get('api_key')
        self.timeout = self.params.get('timeout', 30)
        # ... etc
        return True
```

## Common Parameter Patterns

### API Keys and Secrets

Always mark sensitive parameters as `hidden` and provide an `env_var` option:

```python
"api_key": {
    "type": "string",
    "description": "API key for authentication",
    "required": True,
    "hidden": True,
    "env_var": "SERVICE_API_KEY"
}
```

### Numeric Parameters with Constraints

Use `min` and `max` to enforce valid ranges:

```python
"port": {
    "type": "integer",
    "description": "Server port number",
    "default": 8080,
    "required": False,
    "min": 1,
    "max": 65535
}
```

### Enumerated Values

Use `enum` to restrict to specific values:

```python
"log_level": {
    "type": "string",
    "description": "Logging level",
    "default": "info",
    "required": False,
    "enum": ["debug", "info", "warning", "error"]
}
```

### Optional Features

Use boolean parameters for optional features:

```python
"enable_analytics": {
    "type": "boolean",
    "description": "Enable analytics tracking",
    "default": False,
    "required": False
}
```

## Base Parameters

All skills automatically inherit these base parameters from `SkillBase`:

- **`swaig_fields`** (object) - Additional SWAIG function metadata to merge into tool definitions
- **`tool_name`** (string) - Custom name for skill instances (only for skills with `SUPPORTS_MULTIPLE_INSTANCES = True`)

## Examples

### Simple Skill (No Parameters)

Skills like `datetime` and `math` that don't need configuration:

```python
@classmethod
def get_parameter_schema(cls) -> Dict[str, Dict[str, Any]]:
    # Just return base schema
    return super().get_parameter_schema()
```

### Complex Skill (Many Parameters)

Skills like `web_search` with multiple configuration options:

```python
@classmethod
def get_parameter_schema(cls) -> Dict[str, Dict[str, Any]]:
    schema = super().get_parameter_schema()
    
    schema.update({
        # API credentials (hidden)
        "api_key": {...},
        "api_secret": {...},
        
        # Configuration options
        "timeout": {...},
        "retry_count": {...},
        
        # Feature flags
        "enable_cache": {...},
        "debug_mode": {...},
        
        # Customization
        "response_template": {...},
        "error_messages": {...}
    })
    
    return schema
```

## Best Practices

1. **Always provide descriptions** - Make parameters self-documenting
2. **Set sensible defaults** - Allow skills to work with minimal configuration
3. **Mark secrets as hidden** - Protect sensitive information in UIs
4. **Use appropriate types** - Enable proper validation and UI controls
5. **Document environment variables** - Show alternative configuration methods
6. **Validate in setup()** - Ensure all required parameters are present
7. **Support backward compatibility** - Handle deprecated parameters gracefully

## Future Enhancements

The parameter schema system is designed to be extensible. Future enhancements may include:

- **Conditional parameters** - Show/hide based on other parameter values
- **Complex validation** - Cross-parameter validation rules
- **Nested schemas** - Support for complex object parameters
- **Internationalization** - Localized descriptions and error messages
- **Runtime parameter updates** - Modify configuration without restart