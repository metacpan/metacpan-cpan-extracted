import { Head, Link, router } from '@inertiajs/react'

interface Stats {
  total_todos: number
  completed_todos: number
  pending_todos: number
}

interface Metrics {
  last_updated: string
  random_metric: number
  server_load: string
}

interface Todo {
  id: number
  title: string
  completed: boolean
}

interface Props {
  stats: Stats
  metrics: Metrics
  recent_todos: Todo[]
}

export default function Dashboard({ stats, metrics, recent_todos }: Props) {
  const handleRefreshMetrics = () => {
    router.reload({ only: ['metrics'] })
  }

  return (
    <div className="min-h-screen bg-gray-50 py-12 px-4">
      <Head title="Dashboard" />
      <div className="max-w-4xl mx-auto">
        <h1 className="text-3xl font-bold text-gray-900 mb-8">Dashboard</h1>

        {/* Stats Section */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mb-8">
          <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
            <h3 className="text-sm font-medium text-gray-500">Total Todos</h3>
            <p className="text-2xl font-bold text-gray-900 mt-2">{stats.total_todos}</p>
          </div>
          <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
            <h3 className="text-sm font-medium text-gray-500">Completed</h3>
            <p className="text-2xl font-bold text-green-600 mt-2">{stats.completed_todos}</p>
          </div>
          <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
            <h3 className="text-sm font-medium text-gray-500">Pending</h3>
            <p className="text-2xl font-bold text-yellow-600 mt-2">{stats.pending_todos}</p>
          </div>
        </div>

        {/* Metrics Section */}
        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6 mb-8">
          <div className="flex justify-between items-center mb-4">
            <h2 className="text-xl font-semibold text-gray-900">System Metrics</h2>
            <button
              onClick={handleRefreshMetrics}
              className="px-3 py-1 text-sm bg-blue-600 text-white rounded hover:bg-blue-700"
            >
              Refresh Metrics Only
            </button>
          </div>
          <div className="space-y-2 text-sm">
            <p><span className="font-medium">Last Updated:</span> {metrics.last_updated}</p>
            <p><span className="font-medium">Random Metric:</span> {metrics.random_metric}</p>
            <p><span className="font-medium">Server Load:</span> {metrics.server_load}</p>
          </div>
        </div>

        {/* Recent Todos Section */}
        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6 mb-8">
          <h2 className="text-xl font-semibold text-gray-900 mb-4">Recent Todos</h2>
          {recent_todos.length === 0 ? (
            <p className="text-gray-500">No todos yet</p>
          ) : (
            <ul className="space-y-2">
              {recent_todos.map(todo => (
                <li key={todo.id} className="flex items-center">
                  <span className={`flex-1 ${todo.completed ? 'line-through text-gray-500' : ''}`}>
                    {todo.title}
                  </span>
                  <span className="ml-2">
                    {todo.completed ? '✓' : '○'}
                  </span>
                </li>
              ))}
            </ul>
          )}
        </div>

        <div className="flex gap-4">
          <Link
            href="/"
            className="text-blue-600 hover:underline"
          >
            ← Back to Home
          </Link>
          <Link
            href="/todos"
            className="text-blue-600 hover:underline"
          >
            View All Todos
          </Link>
        </div>
      </div>
    </div>
  )
}