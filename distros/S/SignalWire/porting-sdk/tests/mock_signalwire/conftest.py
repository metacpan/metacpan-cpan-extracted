"""Shared fixtures for mock-signalwire tests."""

from __future__ import annotations

import socket
import sys
from pathlib import Path

import pytest


# Allow `import mock_signalwire` to resolve without an editable install.
# The package lives at ``../../test_harness/mock_signalwire/mock_signalwire/``
# from this conftest. Walk this file's parents looking for a directory named
# ``test_harness`` containing the named package.
def _discover_mock_package(name: str) -> bool:
    here = Path(__file__).resolve()
    for parent in here.parents:
        candidate = parent / "test_harness" / name
        if (candidate / name / "__init__.py").is_file():
            entry = str(candidate)
            if entry not in sys.path:
                sys.path.insert(0, entry)
            return True
    return False


_discover_mock_package("mock_signalwire")

from mock_signalwire import MockServer


def _free_port() -> int:
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.bind(("127.0.0.1", 0))
    port = s.getsockname()[1]
    s.close()
    return port


@pytest.fixture(scope="session")
def mock_server() -> MockServer:
    """Boot one mock server for the whole test session."""
    srv = MockServer(host="127.0.0.1", port=_free_port(), log_level="error").start()
    yield srv
    srv.stop()


@pytest.fixture(autouse=True)
def _reset_state(mock_server: MockServer):
    """Reset journal + scenarios between tests so each test gets a clean slate."""
    mock_server.app.state.mock_state.journal.reset()
    mock_server.app.state.mock_state.scenarios.reset()
    yield
